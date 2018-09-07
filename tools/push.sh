#!/bin/bash

for b in `cat temp`; do
	git push origin $b:dev/4.18/staging/$b
done

