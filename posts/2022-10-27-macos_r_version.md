---
title: "Install multiple version of R in MacOS"
date: "2020-11-27"
categories: ["MacOS", "R"]
image: "https://www.macworld.com/wp-content/uploads/2022/04/mac-recovery-mode.jpg"
---

Mac, by default, save R executable and relevant libraries at `/Library/Frameworks/R.framework/Versions/`. Here is the tree structure of my "R.framework" (`tree -L 3 /Library/Frameworks/R.framework`)

```sh
/Library/Frameworks/R.framework
├── Headers -> Versions/Current/Headers
├── Libraries -> Versions/Current/Resources/lib
├── PrivateHeaders -> Versions/Current/PrivateHeaders
├── R -> Versions/Current/R
├── Resources -> Versions/Current/Resources
└── Versions
    ├── 4.1
    │   ├── Headers -> Resources/include
    │   ├── PrivateHeaders
    │   ├── R -> Resources/lib/libR.dylib
    │   └── Resources
    └── Current -> /Library/Frameworks/R.framework/Versions/4.1
```

-   The R package libraries were saved under `Resources/library`
-   R which is symbolic linked to `Resources/lib/libR.dylib` is the executable.

Usually, if you just download new version binary installer (`*.pkg`) from [CRAN](https://cran.r-project.org/) and use GUI to install, it will 1) remove the original executable, 2) symbolic link `Current` to the new version.

1.  get source package from https://mac.r-project.org/

```sh
# download source
 curl -O https://mac.r-project.org/high-sierra/R-4.2-branch/x86_64/R-4.2-branch.tar.gz

# extract to folder 4.2
mkdir -p 4.2/
tar xfzv R-4.2-branch.tar.gz --directory 4.2
```

2.  move to destination folder Inside 4.2 folder will be very similar to mac structure `Library/Frameworks/R.framework/Versions/4.2`, thus copy it to mac default R folder `/Library/Frameworks/R.framework/Versions/4.2`

```sh
# rm -rf /Library/Frameworks/R.framework/Versions/4.2
cp -R Library/Frameworks/R.framework/Versions/4.2 /Library/Frameworks/R.framework/Versions/
```

3.  install Rswitch

[Rswitch](https://rud.is/rswitch/) is a light-weight utility for macOS R users, which can help easily switch active R version. It basically re-establish symbolic link of `Current` mentioned above to the version you selected.

After installation and open, Rswitch shows as a little control panel at right corner of top menu.

4.  
