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

FactoryGirl.define do

  factory :test_counter do
    timezone{ Time.zone.name }
    timestamp{ Time.now.utc }
    mask 0
    unique_token{ "#{timezone}:#{timestamp.strftime('%Y-%m-%d')}:#{mask}:" }
    written_counter{ rand(100) }
    run_counter{ rand(100) }
  end
end
