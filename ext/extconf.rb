require 'mkmf'

$CFLAGS += " -DRUBY_19" if RUBY_VERSION =~ /1.9/

extension_name = "raise_awareness"
dir_config(extension_name)
create_makefile(extension_name)
