if ! [ -d cr ]
then
    echo "Fetching modified Crystal standard library..."
    if ! command -v git &> /dev/null
    then
        echo "Git not found. Abort."
        exit 1
    fi
    git clone https://github.com/sugarfi/crystal.git cr
fi
if ! command -v make &> /dev/null
then
    echo "Make not found. Abort."
    exit 1
fi
if ! command -v crystal &> /dev/null
then
    echo "Crystal not found. Abort."
    exit 1
fi
if ! command -v gcc &> /dev/null
then
    echo "GCC not found. Abort."
    exit 1
fi
if ! command -v shards &> /dev/null
then
    echo "Shards not found. Abort."
    exit 1
fi
if ! [[ "$(crystal -v)" =~ "0.35.1" ]]
then
    echo "Crystal must be version 0.35.1 to build. Abort."
    exit 1
fi
if ! [[ "$(shards --version)" =~ 0.1[12].1 ]]
then
    echo "Shards must be version 0.12.1 or 0.11.1 to build. Abort."
    exit 1
fi
cd cr/ && make libcrystal && cd ..
export CRYSTAL_PATH="$(pwd)/cr/src:$(pwd)/lib" && make sdx
exit