From 37b6bf1243b894e0da6e640e589d479f3208f5ae Mon Sep 17 00:00:00 2001
From: Vivek Kasireddy <vivek.kasireddy@intel.com>
Date: Thu, 4 Apr 2024 00:26:15 -0700
Subject: [PATCH 8/8] selftests/udmabuf: Add tests to verify data after page
 migration

Since the memfd pages associated with a udmabuf may be migrated
as part of udmabuf create, we need to verify the data coherency
after successful migration. The new tests added in this patch try
to do just that using 4k sized pages and also 2 MB sized huge
pages for the memfd.

Successful completion of the tests would mean that there is no
disconnect between the memfd pages and the ones associated with
a udmabuf. And, these tests can also be augmented in the future
to test newer udmabuf features (such as handling memfd hole punch).

The idea for these tests comes from a patch by Mike Kravetz.

Cc: Shuah Khan <shuah@kernel.org>
Cc: David Hildenbrand <david@redhat.com>
Cc: Daniel Vetter <daniel.vetter@ffwll.ch>
Cc: Mike Kravetz <mike.kravetz@oracle.com>
Cc: Hugh Dickins <hughd@google.com>
Cc: Peter Xu <peterx@redhat.com>
Cc: Jason Gunthorpe <jgg@nvidia.com>
Cc: Gerd Hoffmann <kraxel@redhat.com>
Cc: Dongwon Kim <dongwon.kim@intel.com>
Cc: Junxiao Chang <junxiao.chang@intel.com>
Signed-off-by: Vivek Kasireddy <vivek.kasireddy@intel.com>
---
 .../selftests/drivers/dma-buf/udmabuf.c       | 151 +++++++++++++++++-
 1 file changed, 147 insertions(+), 4 deletions(-)

diff --git a/tools/testing/selftests/drivers/dma-buf/udmabuf.c b/tools/testing/selftests/drivers/dma-buf/udmabuf.c
index c812080e304e..d76c813fe652 100644
--- a/tools/testing/selftests/drivers/dma-buf/udmabuf.c
+++ b/tools/testing/selftests/drivers/dma-buf/udmabuf.c
@@ -9,26 +9,132 @@
 #include <errno.h>
 #include <fcntl.h>
 #include <malloc.h>
+#include <stdbool.h>
 
 #include <sys/ioctl.h>
 #include <sys/syscall.h>
+#include <sys/mman.h>
 #include <linux/memfd.h>
 #include <linux/udmabuf.h>
 
 #define TEST_PREFIX	"drivers/dma-buf/udmabuf"
 #define NUM_PAGES       4
+#define NUM_ENTRIES     4
+#define MEMFD_SIZE      1024 /* in pages */
 
-static int memfd_create(const char *name, unsigned int flags)
+static unsigned int page_size;
+
+static int create_memfd_with_seals(off64_t size, bool hpage)
+{
+	int memfd, ret;
+	unsigned int flags = MFD_ALLOW_SEALING;
+
+	if (hpage)
+		flags |= MFD_HUGETLB;
+
+	memfd = memfd_create("udmabuf-test", flags);
+	if (memfd < 0) {
+		printf("%s: [skip,no-memfd]\n", TEST_PREFIX);
+		exit(77);
+	}
+
+	ret = fcntl(memfd, F_ADD_SEALS, F_SEAL_SHRINK);
+	if (ret < 0) {
+		printf("%s: [skip,fcntl-add-seals]\n", TEST_PREFIX);
+		exit(77);
+	}
+
+	ret = ftruncate(memfd, size);
+	if (ret == -1) {
+		printf("%s: [FAIL,memfd-truncate]\n", TEST_PREFIX);
+		exit(1);
+	}
+
+	return memfd;
+}
+
+static int create_udmabuf_list(int devfd, int memfd, off64_t memfd_size)
+{
+	struct udmabuf_create_list *list;
+	int ubuf_fd, i;
+
+	list = malloc(sizeof(struct udmabuf_create_list) +
+		      sizeof(struct udmabuf_create_item) * NUM_ENTRIES);
+	if (!list) {
+		printf("%s: [FAIL, udmabuf-malloc]\n", TEST_PREFIX);
+		exit(1);
+	}
+
+	for (i = 0; i < NUM_ENTRIES; i++) {
+		list->list[i].memfd  = memfd;
+		list->list[i].offset = i * (memfd_size / NUM_ENTRIES);
+		list->list[i].size   = getpagesize() * NUM_PAGES;
+	}
+
+	list->count = NUM_ENTRIES;
+	list->flags = UDMABUF_FLAGS_CLOEXEC;
+	ubuf_fd = ioctl(devfd, UDMABUF_CREATE_LIST, list);
+	free(list);
+	if (ubuf_fd < 0) {
+		printf("%s: [FAIL, udmabuf-create]\n", TEST_PREFIX);
+		exit(1);
+	}
+
+	return ubuf_fd;
+}
+
+static void write_to_memfd(void *addr, off64_t size, char chr)
+{
+	int i;
+
+	for (i = 0; i < size / page_size; i++) {
+		*((char *)addr + (i * page_size)) = chr;
+	}
+}
+
+static void *mmap_fd(int fd, off64_t size)
+{
+	void *addr;
+
+	addr = mmap(NULL, size, PROT_READ|PROT_WRITE, MAP_SHARED, fd, 0);
+	if (addr == MAP_FAILED) {
+		printf("%s: ubuf_fd mmap fail\n", TEST_PREFIX);
+		exit(1);
+	}
+
+	return addr;
+}
+
+static int compare_chunks(void *addr1, void *addr2, off64_t memfd_size)
 {
-	return syscall(__NR_memfd_create, name, flags);
+	off64_t off;
+	int i = 0, j, k = 0, ret = 0;
+	char char1, char2;
+
+	while (i < NUM_ENTRIES) {
+		off = i * (memfd_size / NUM_ENTRIES);
+		for (j = 0; j < NUM_PAGES; j++, k++) {
+			char1 = *((char *)addr1 + off + (j * getpagesize()));
+			char2 = *((char *)addr2 + (k * getpagesize()));
+			if (char1 != char2) {
+				ret = -1;
+				goto err;
+			}
+		}
+		i++;
+	}
+err:
+	munmap(addr1, memfd_size);
+	munmap(addr2, NUM_ENTRIES * NUM_PAGES * getpagesize());
+	return ret;
 }
 
 int main(int argc, char *argv[])
 {
 	struct udmabuf_create create;
 	int devfd, memfd, buf, ret;
-	off_t size;
-	void *mem;
+	off64_t size;
+	void *addr1, *addr2;
 
 	devfd = open("/dev/udmabuf", O_RDWR);
 	if (devfd < 0) {
@@ -90,6 +196,9 @@ int main(int argc, char *argv[])
 	}
 
 	/* should work */
+	page_size = getpagesize();
+	addr1 = mmap_fd(memfd, size);
+	write_to_memfd(addr1, size, 'a');
 	create.memfd  = memfd;
 	create.offset = 0;
 	create.size   = size;
@@ -98,6 +207,40 @@ int main(int argc, char *argv[])
 		printf("%s: [FAIL,test-4]\n", TEST_PREFIX);
 		exit(1);
 	}
+	munmap(addr1, size);
+	close(buf);
+	close(memfd);
+
+	/* should work (migration of 4k size pages)*/
+	size = MEMFD_SIZE * page_size;
+	memfd = create_memfd_with_seals(size, false);
+	addr1 = mmap_fd(memfd, size);
+	write_to_memfd(addr1, size, 'a');
+	buf = create_udmabuf_list(devfd, memfd, size);
+	addr2 = mmap_fd(buf, NUM_PAGES * NUM_ENTRIES * getpagesize());
+	write_to_memfd(addr1, size, 'b');
+	ret = compare_chunks(addr1, addr2, size);
+	if (ret < 0) {
+		printf("%s: [FAIL,test-5]\n", TEST_PREFIX);
+		exit(1);
+	}
+	close(buf);
+	close(memfd);
+
+	/* should work (migration of 2MB size huge pages)*/
+	page_size = getpagesize() * 512; /* 2 MB */
+	size = MEMFD_SIZE * page_size;
+	memfd = create_memfd_with_seals(size, true);
+	addr1 = mmap_fd(memfd, size);
+	write_to_memfd(addr1, size, 'a');
+	buf = create_udmabuf_list(devfd, memfd, size);
+	addr2 = mmap_fd(buf, NUM_PAGES * NUM_ENTRIES * getpagesize());
+	write_to_memfd(addr1, size, 'b');
+	ret = compare_chunks(addr1, addr2, size);
+	if (ret < 0) {
+		printf("%s: [FAIL,test-6]\n", TEST_PREFIX);
+		exit(1);
+	}
 
 	fprintf(stderr, "%s: ok\n", TEST_PREFIX);
 	close(buf);
-- 
2.25.1

