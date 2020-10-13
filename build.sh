if ! command -v docker &> /dev/null
then
    echo "Docker not found, attempting to build with Make..."
    echo -e "\e[33mWARNING: building with Make produces binaries incompatible with other Glibc versions. Installing Docker to build with Musl is recommened.\e[0m"
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
    make sdx
    exit
fi

echo "Building with Docker..."
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
docker build -t sugarfi/sdx:latest .
docker cp $(docker run -d sugarfi/sdx):/root/bin/sdx bin