rm -rf ./build
yarn build

# remove remote files
# cd ~/blog
# rm -rf ./*
scp -r ./build/* tencent:~/blog
