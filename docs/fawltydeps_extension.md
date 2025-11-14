<!-- Generated with Stardoc: http://skydoc.bazel.build -->

Implementation of rules_fawltydeps 'fawltydeps' extension

<a id="fawltydeps"></a>

## fawltydeps

<pre>
fawltydeps = use_extension("@rules_fawltydeps//fawltydeps/extensions:fawltydeps.bzl", "fawltydeps")
fawltydeps.configure(<a href="#fawltydeps.configure-name">name</a>, <a href="#fawltydeps.configure-pip_repo">pip_repo</a>)
</pre>

Bzlmod extension that is used to configure fawltydeps.


**TAG CLASSES**

<a id="fawltydeps.configure"></a>

### configure

Tag class used to configure which pip repo to use with fawltydeps

**Attributes**

| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="fawltydeps.configure-name"></a>name |  The repository name to create. Default to "fawltydeps".   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | optional |  `"fawltydeps"`  |
| <a id="fawltydeps.configure-pip_repo"></a>pip_repo |  The label of the pip repository that you want fawltydeps to use to generate mappings between import names and module names. Will also be used to suggest names for missing modules.<br><br>If you are using the same names as rules_python documentation this would be "@pypi"   | <a href="https://bazel.build/concepts/labels">Label</a> | required |  |


