rm -rf files
mkdir files
gem install sardonyx --install-dir files
export GEM_HOME=$(pwd)/files
files/gems/sardonyx-0.3.3/bin/sdx