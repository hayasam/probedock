# Copyright (c) 2015 ProbeDock
# Copyright (c) 2012-2014 Lotaris SA
#
# This file is part of ProbeDock.
#
# ProbeDock is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# ProbeDock is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with ProbeDock.  If not, see <http://www.gnu.org/licenses/>.
module ProbeDock
  class TestKeysApi < Grape::API
    namespace :'test-keys' do
      before do
        authenticate!
      end

      helpers do
        def parse_key
          parse_object :key, :projectId
        end

        def current_organization
          @current_organization ||= if params[:organizationId].present?
            Organization.active.where(api_id: params[:organizationId].to_s).first!
          elsif params[:organizationName].present?
            Organization.active.where(normalized_name: params[:organizationName].to_s.downcase).first!
          end
        end
      end

      post do
        data = parse_key

        # TODO: limit n
        if params[:n].to_s.to_i >= 1

          project = Project.where(api_id: data[:project_id].to_s).includes(:organization).first!
          key = TestKey.new user: current_user, project: project
          authorize! key, :create

          Array.new(params[:n].to_s.to_i) do
            serialize TestKey.new(user: current_user, project: project).tap(&:save!)
          end
        else
          key = TestKey.new key: data[:key], user: current_user
          key.user = current_user
          key.project = Project.where(api_id: data[:project_id].to_s).includes(:organization).first

          authorize! key, :create

          create_record key
        end
      end

      get do
        authorize! TestKey, :index

        rel = policy_scope(TestKey).joins(:project).includes(:project, :user).order('projects.normalized_name ASC, test_keys.created_at ASC, test_keys.key ASC')

        rel = paginated rel do |rel|
          rel = rel.where projects: { organization_id: current_organization.id } if current_organization
          rel = rel.where free: true_flag?(:free) if params.key? :free
          rel = rel.joins(:user).where 'users.api_id = ?', params[:userId].to_s if params.key? :userId
          rel
        end

        serialize load_resources(rel)
      end

      delete do
        authorize! TestKey, :release

        TestKey.joins('LEFT OUTER JOIN test_keys_payloads ON test_keys.id = test_keys_payloads.test_key_id').where(user: current_user, free: true).where('test_keys_payloads.test_key_id IS NULL').delete_all

        status 204
        nil
      end
    end
  end
end
