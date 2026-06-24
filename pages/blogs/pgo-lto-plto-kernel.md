# TODO: Heading

It took me quite sometime to finish the experiments and complete the blog
because I took a small break from work, come across some oom issues with grub
while installing the kernel with a large initrd and finishing the long list of
experiments itself including the clang builds that I lost from the earlier
experiments is just a bit tiring when I want to start again. Since I took a long
enough break with some regret I am back at it again.

## Kernel builds

For raw scripts and results checkout this
[link](https://github.com/sidchintamaneni/blog/blob/blog/pgo-lto-plto/pages/blogs/data/pgo-lto-plto/pgo-lto-plto-experiments-2.md)

Since we've multiple compiler builds from the earlier experiments (not true I
had to rebuild everything again) and kernel itself is a big enough binary it is
nice to how they perform. I picked default gcc that ships with azl, O2 clang
and Clang with O3, ThinLTO, AutoFDO and propeller. It is not a surprise that
final clang build with all the optimizations performed better than the rest.



## Final thoughts

Even though looking at the results and understanding the parts that I am
interested in is a bit rewarding but the experiments, waiting for the results and re-doing the
experiments itself till I am satisfied is a bit tiring. Probably I'll chose the next project to be
more impl'ny and less waiting for results to come back or probably a hybrid
version of both. I don't want to lose the context and question I have while
working on these experiments so I think blogs can serve as context and I'll list
the questions down below.
