#!/user/bin/env python

import sys
import os
from hashlib import sha1
from fuzzywuzzy import fuzz
from fuzzywuzzy import process  # <- not sure I need this one
# chromeos-rebase toolusesthis one for porcess.extractOne function.
# I might use process.extract with a "choices" list see:
# http://jonathansoma.com/lede/algorithms-2017/classes/fuzziness-matplotlib/fuzzing-matching-in-pandas-with-fuzzywuzzy/


def readin_patch(filename):
    try:
        file = open(filename)
        patch = file.read()
        file.close()
    except IsADirectoryError:
        patch = None

    return patch


def writeout_patch(filename, patch):
    if patch:
        file = open(filename, 'w')
        lines = patch.splitlines(keepends=True)
        for line in lines:
            file.write(line)

        file.close()


def make_changeid(patch):
    changeid = sha1(patch.encode('utf-8')).hexdigest()
    retval = "Change-Id: I" + changeid + '\n'
    return retval


def insert_changeid(patch, changeid):
    line_num = 0
    existing_changeid_count = 0
    updated_patch = ""
    last_empty_line = 0
    lines = patch.splitlines(keepends=True)
    for line in lines:
        if len(line) == 1:
            last_empty_line = line_num

        if line.find("Change-Id") == 0:
            existing_changeid_count += 1

        if line.find("Signed-off-by:") == 0:
            if last_empty_line == 0:
                last_empty_line = line_num - 1
            break

        if line == '---\n':
            break
        line_num += 1

    if line_num == len(lines):
        return None

    line_num = 0
    for line in lines:
        if line.find("Change-Id") != 0:
            updated_patch += line
        if line_num == (last_empty_line + 1 - existing_changeid_count):
            updated_patch += changeid
        line_num += 1

    return updated_patch


def get_changeid(patch):
    line_num = 0
    last_changeid = 0
    lines = patch.splitlines(keepends=True)
    for line in lines:
        if line == '---\n':
            break
        if line.find("Change-Id") == 0:
            if len(line.split()) == 2:
                last_changeid = line_num
        line_num += 1

    if line_num == len(lines):
        return None

    if last_changeid:
        return lines[last_changeid]

    return None


def extract_commit_comment(patch):
    comment = ""
    flag = False
    subject_line = False
    lines = patch.splitlines(keepends=True)
    for line in lines:
        if line == '---\n':
            break

        # skip any Change-Id lines.
        if line.find("Change-Id") == 0:
            continue
        # skip any Signed-off-by lines.
        if line.find("Signed-off-by:") == 0:
            continue
        # some ugly logic to skip the subject lines (assumes only 2 lines)
        if flag:
            comment += line
        if subject_line:
            flag = True
        if line.find("Subject:") == 0:
            subject_line = True

    if len(comment) == len(patch):
        return None

    return comment


def extract_hunks(patch):
    flag = False
    hunks = ""
    lines = patch.splitlines(keepends=True)
    for line in lines:
        if line == '---\n':
            flag = True
            continue  # we don't want to include the "---"

        #next skip all hunk headers that don't add much to the diff.
        if line.find("diff ") == 0 || line.find("index ") == 0 ||
           line.find("--- ") == 0 || line.find("+++ ") == 0 ||
           line.find("@@ ") == 0:
            continue

        if flag:
            hunks += line

    if not flag:
        return None

    return hunks


def get_author(patch):
    lines = patch.splitlines(keepends=True)
    from_line = ""
    for line in lines:
        if line == '---\n':
            break
        if line.find("From:") == 0:
            from_line = line

    return from_line


def get_date_stamp(patch):
    lines = patch.splitlines(keepends=True)
    date_line = ""
    for line in lines:
        if line == '---\n':
            break
        if line.find("Date:") == 0:
            date_line = line

    return date_line


def get_subject(patch):
    index = 0
    subject = ""
    lines = patch.splitlines(keepends=True)
    for line in lines:
        if line == '---\n':
            break
        if line.find("Subject:") == 0:
            subject = line
            if len(lines[index+1]):
                subject += lines[index+1]

        index += 1

    return subject


def load_patches(path, series):
    ret_dict = {}
    for file in series:
        if file[0] == '#':
            continue
        patch = readin_patch(os.path.join(path, file))
        author = get_author(patch)
        date = get_date_stamp(patch)
        subject = get_subject(patch)
        comment = extract_commit_comment(patch)
        hunks = extract_hunks(patch)
        changeid = get_changeid(patch)
        if author and date:
            ret_dict[file] = [file, date, author, subject, changeid,
                              comment, hunks, patch]

    return ret_dict


def match_indexed_field(index, patch, old_patch_dict):
    if (index in range(8)) and patch and patch[index] and old_patch_dict:
        # lookout for matching very shortstrings!
        if len(patch[index]) < 5:
            return ((None, 0, None), (None, 0, None))

        choices = dict([(f, old_patch_dict[f][index]) for f in
                        old_patch_dict.keys()])

        try:
            ratio = process.extractOne(patch[index], choices,
                                       scorer=fuzz.ratio)

            set_ratio = process.extractOne(patch[index], choices,
                                           scorer=fuzz.token_set_ratio)
        except:
            print(choices.keys(), len(choices), patch[0])
            return ((None, 0, None), (None, 0, None))

        return (ratio, set_ratio)
    return ((None, 0, None), (None, 0, None))


def match_comment(patch, old_patch_dict):
    return match_indexed_field(5, patch, old_patch_dict)


def match_hunks(patch, old_patch_dict):
    return match_indexed_field(6, patch, old_patch_dict)


def match_subject(patch, old_patch_dict):
    return match_indexed_field(3, patch, old_patch_dict)


def match_authors(patch, old_patch_dict):
    return match_indexed_field(2, patch, old_patch_dict)


def match_date(patch, old_patch_dict):
    return match_indexed_field(1, patch, old_patch_dict)


def match_changeid(patch, old_patch_dict):
    if patch and patch[4] and old_patch_dict:
        for k in old_patch_dict.keys():
            old_patch = old_patch_dict[k]
            if (len(old_patch[4].split())) == 2:  # only check standard Change-Id lines
                if patch[4].split()[1] == old_patch[4].split()[1]:
                    return old_patch
    else:
        print(patch, patch[4], old_patch_dict.keys())
    print("no change-id match found for: ", patch[0], patch[4].split())
#    import pdb; pdb.set_trace()
    return None


def find_matching_subject(patch, old_patch_dict):
    # algorithm:
    # 1 fuzy compare body of patch and if close enough then assume the match.
    # 2 fuzzy compare subject fuzy compare commit comment if close enough then
    # assume the match
    # otherwise no-match

    if len(old_patch_dict) == 0:
        return None

    subject_key = None

    ((rstr, rscore, rkey),
     (sstr, sscore, skey)) = match_subject(patch, old_patch_dict)
    if rkey and skey and rkey == skey:
        score = rscore + sscore
        if score > 180:
            return subject_key

    return None


def find_matching_commit_dominate(patch, old_patch_dict):
    # algorithm:
    # 1 fuzy compare body of patch and if close enough then assume the match.
    # 2 fuzzy compare subject fuzy compare commit comment if close enough then
    # assume the match
    # otherwise no-match

    if len(old_patch_dict) == 0:
        return None

    comment_key = None

    ((rstr, rscore, rkey),
     (sstr, sscore, skey)) = match_comment(patch, old_patch_dict)
    if rkey and skey and rkey == skey:
        score = rscore + sscore
        if score > 170:
            # print("comment match", score, rkey)
            comment_key = rkey
            # optimization if comment matches and ratios look good call it good
            # enough.
            ratio = fuzz.ratio(patch[6], old_patch_dict[comment_key][6])
            set_ratio = fuzz.token_set_ratio(patch[6],
                                             old_patch_dict[comment_key][6])
            if set_ratio + ratio > 175:
                # print("hunk match score : ", set_ratio + ratio)
                return comment_key

    return None


def find_matching_patch(patch, old_patch_dict):
    # algorithm:
    # 1 fuzy compare body of patch and if close enough then assume the match.
    # 2 fuzzy compare subject fuzy compare commit comment if close enough then
    # assume the match
    # otherwise no-match

    if len(old_patch_dict) == 0:
        return None

    hunks_key = None

    ((rstr, rscore, rkey),
     (sstr, sscore, skey)) = match_hunks(patch, old_patch_dict)
    # match_hunks can take a long time. 90+ seconds
    if rkey and skey and rkey == skey:
        score = rscore + sscore
        if score > 175:
            # print("hunks match", score, rkey)
            hunks_key = rkey

    if hunks_key:
        return hunks_key

    return None


def orginal_find_matching_patch(patch, old_patch_dict):
    # algorithm:
    # 1 fuzy compare body of patch and if close enough then assume the match.
    # 2 fuzzy compare subject fuzy compare commit comment if close enough then
    # assume the match
    # otherwise no-match

    if len(old_patch_dict) == 0:
        return None

    hunks_key = None
    comment_key = None

    ((rstr, rscore, rkey),
     (sstr, sscore, skey)) = match_comment(patch, old_patch_dict)
    if rkey and skey and rkey == skey:
        score = rscore + sscore
        if score > 175:
            # print("comment match", score, rkey)
            comment_key = rkey
            # optimization if comment matches and ratios look good call it good
            # enough.
            ratio = fuzz.ratio(patch[6], old_patch_dict[comment_key][6])
            set_ratio = fuzz.token_set_ratio(patch[6],
                                             old_patch_dict[comment_key][6])
            if set_ratio + ratio > 160:
                return comment_key

    ((rstr, rscore, rkey),
     (sstr, sscore, skey)) = match_hunks(patch, old_patch_dict)
    # match_hunks can take a long time. 90+ seconds
    if rkey and skey and rkey == skey:
        score = rscore + sscore
        if score > 175:
            # print("hunks match", score, rkey)
            hunks_key = rkey

    if hunks_key:
        return hunks_key

    if comment_key:
        return comment_key

    return None


def check_for_changeid_collisions():
    return


def my_print(list_of_patches):
    dict_of_lists = {}
    for p in list_of_patches:
        split_p = p.split(".")
        if split_p[-1] in dict_of_lists.keys():
            dict_of_lists[split_p[-1]].append(p)
        else:
            dict_of_lists[split_p[-1]] = [p]

    for p in dict_of_lists.keys():
        dict_of_lists[p].sort()
        print(" ")
        print("*** ", p, " ***")
        for name in dict_of_lists[p]:
            print(name)


def main(oldpath, newpath, series):
    file = open(os.path.join(oldpath, series))
    temp = file.read()
    oldpatches = temp.splitlines()
    file.close()

    file = open(os.path.join(newpath, series))
    temp = file.read()
    newpatches = temp.splitlines()
    file.close()

    old_patch_dic = load_patches(oldpath, oldpatches)
    new_patch_dic = load_patches(newpath, newpatches)
    new_patches = []
    new_matches = []

    # match on commit comment with checks on hunks
    for key in new_patch_dic.keys():
        patch = new_patch_dic[key]
        match = find_matching_commit_dominate(patch, old_patch_dic)
        if match:
            # remove match from old and new dict as optimization:
            del old_patch_dic[match]
            new_matches.append(key)

    # reduce the new_patch_dic to just whats not matched yet:
    for k in new_matches:
        del new_patch_dic[k]

    # finally do it the hard way.  (can be very slow)
    for key in new_patch_dic.keys():
        patch = new_patch_dic[key]
        match = find_matching_patch(patch, old_patch_dic)
        if match:
            # remove match from old dict as optimization:
            del old_patch_dic[match]
        else:  # no match / new patch
            new_patches.append(key)
            # print("no match for", key)

    # finally identify significantly updated changes.
    changed_patches = []
    for key in new_patch_dic.keys():
        patch = new_patch_dic[key]
        match = find_matching_subject(patch, old_patch_dic)
        if match:
            changed_patches.append(key)
            del old_patch_dic[match]

    print("********* updated patches ********* :")
    print("********* updated patches ********* :")
    print("********* updated patches ********* :")
    print(" ")
    my_print(changed_patches)
    print(" ")
    print("********* orphined patches ********* :")
    print("********* orphined patches ********* :")
    print("********* orphined patches ********* :")
    print(" ")
    my_print(old_patch_dic.keys())
    print(" ")
    print("********* new patches ********* :")
    print("********* new patches ********* :")
    print("********* new patches ********* :")
    print(" ")
    my_print(new_patches)

# from the ophined patches left find the ones with matching subject and commit
# comments that have significant updates.


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2], sys.argv[3])
