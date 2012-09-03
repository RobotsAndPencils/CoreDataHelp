0. add coredatahelp as a submodule
1. Drag coredatahelp xcodeproj file into the Xcode project it's going to be part of, under the current project.
2. Add a target dependency on coredatahelp (Target->Build Phases->Target Dependencies)
3. Link with the libCoreDataHelp.a library
4. On all targets, add the following items to your header search paths:
4a. $(BUILT_PRODUCTS_DIR/../.. recursive
4b. 8b. $(inherited) non-recursive
5. In the host project, add the preprocessor macro DCA_UNITTEST to the unitest configuration, and DCA_RELEASE / DCA_DEBUG in the appropriate places. This is redundant, but Drew doesn't care
6.  Link against CoreData.framework from both your app and test target
