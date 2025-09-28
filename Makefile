-include .env

ifndef REMOTE_HOST
$(error REMOTE_HOST is not set. Export REMOTE_HOST or create .env with REMOTE_HOST=...)
endif

install:
    bundle install

lint:
    bundle exec rubocop

tests:
    bundle exec rspec --no-profile --format documentation

restart_crone:
    sudo service cron reload

update_remote_yml:
    scp Gemfile common_list.yml deploy.sh my_bot_ruby.rb root@$(REMOTE_HOST):/home/my_bot_ruby/

download_remote_yml:
    scp root@$(REMOTE_HOST):/home/my_bot_ruby/Gemfile root@$(REMOTE_HOST):/home/my_bot_ruby/common_list.yml root@$(REMOTE_HOST):/home/my_bot_ruby/deploy.sh root@$(REMOTE_HOST):/home/my_bot_ruby/my_bot_ruby.rb .