MODULES = m2config

all: $(MODULES)

.PHONY: $(MODULES)
$(MODULES): DIR=lib/$@
$(MODULES): %: %.thrift
	mkdir -p $(DIR)
	thrift --gen rb $<
	mv gen-rb/* $(DIR)
	cd $(DIR); mv $@_types.rb types.rb
	cd $(DIR); mv $@_constants.rb constants.rb
	cd $(DIR); sed -i "" "s/$@_types/$@\/types/" *.rb
	rmdir gen-rb
