rm -rf files
mkdir files
gem install sardonyx --install-dir files
gem install volcano --install-dir files
export GEM_HOME=$(pwd)/files
files/gems/volcano-*/bin/volcano install SardonyxLang/SardonyxStd
source ~/.volcano/env
files/gems/sardonyx-*/bin/sdx