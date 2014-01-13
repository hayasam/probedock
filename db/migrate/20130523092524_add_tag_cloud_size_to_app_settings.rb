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
class AddTagCloudSizeToAppSettings < ActiveRecord::Migration
  class AppSettings < ActiveRecord::Base; end

  def up
    add_column :app_settings, :tag_cloud_size, :integer
    AppSettings.reset_column_information
    AppSettings.update_all tag_cloud_size: 50
    change_column :app_settings, :tag_cloud_size, :integer, null: false
  end

  def down
    remove_column :app_settings, :tag_cloud_size
  end
end
