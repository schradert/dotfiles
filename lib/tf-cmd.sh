#!@bash@

build_d="$(pwd)/build"
[[ ! -d $build_d ]] && mkdir "$build_d"
result="$build_d/config.tf.json"
[[ -e $result ]] && rm -f "$result"
cp @config@ "$result"
@terraform@ -chdir=build init
@terraform@ -chdir=build @command@
