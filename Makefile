.PHONY: demo
VERSION := `cat lib/rack_spa.rb | grep 'VERSION =' | cut -d '"' -f2`

install:
	bundle install
cop:
	bundle exec rubocop
fix:
	bundle exec rubocop --auto-correct-all
fmt: fix

test:
	bundle exec rspec spec/

demo:
	cd demo && bundle exec rackup

build:
ifeq ($(strip $(VERSION)),)
	echo "Could not parse VERSION"
else
	git tag $(VERSION)
	gem build rack-spa.gemspec
	gem push rack-spa-$(VERSION).gem
	git push origin $(VERSION)
endif

