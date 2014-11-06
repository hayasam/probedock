# Copyright (c) 2012-2014 Lotaris SA
#
# This file is part of ROX Center.
#
# ROX Center is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# ROX Center is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with ROX Center.  If not, see <http://www.gnu.org/licenses/>.
require 'highline/import'

namespace :users do

  desc %|Give administrator privileges to a user|
  task :admin, [ :name ] => :environment do |t,args|

    user = User.where(name: args.name).first

    unless user
      puts Paint["No user found with name #{args.name}", :red]
      next
    end

    user.roles << :admin
    user.save!

    puts Paint["User #{user.name} is now an administrator", :green]
  end

  desc %|Register a new user|
  task :register, [ :email, :password ] => :environment do |t,args|

    email = args[:email]
    puts Paint[%/The "email" argument is required/, :red] unless email

    user = User.joins(:email).where(user_emails: { email: email }).first
    puts Paint["There is already a user with e-mail #{email}", :red] if user

    name = email.sub(/\@.*$/, '')
    password = args[:password] || ask('Enter the password of the new user: '){ |q| q.echo = false }
    puts Paint["Password cannot be blank", :red] if password.blank?

    user = User.new name: name, email: UserEmail.new(email: email), password: password
    user.save!

    puts Paint["User #{email} successfully created", :green]
  end

  desc %|Generate an authentication token for a user and export it as $ROX_TOKEN|
  task :token, [ :email ] => :environment do |t,args|

    email = args[:email]
    user = User.joins(:email).where(user_emails: { email: email }).first
    unless user
      puts Paint[%/No user found with e-mail #{email}/, :red]
      next
    end

    puts user.generate_auth_token
  end
end
