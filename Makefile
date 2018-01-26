install:
	ansible-galaxy install -p ./roles -r requirements.yml -f

reset:
	rm -rf ./roles

encrypt:
	./encrypt.sh

decrypt:
	./decrypt.sh
