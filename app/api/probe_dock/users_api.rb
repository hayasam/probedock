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
  class UsersApi < Grape::API

    namespace :users do
      helpers do
        def parse_user
          parse_object :name, :primaryEmail, :active, :technical, :organizationId, :password, :passwordConfirmation
        end

        def current_otp_record
          @current_otp_record ||= if params.key? :membershipOtp
            Membership.where('otp IS NOT NULL').where(otp: params[:membershipOtp].to_s).where('expires_at > ?', Time.now).first
          end
        end

        def with_serialization_includes rel
          rel = rel.includes :memberships if true_flag? :withTechnicalMembership
          rel
        end

        def serialization_options *args
          {
            with_technical_membership: true_flag?(:withTechnicalMembership)
          }
        end
      end

      post do
        authenticate

        data = parse_user
        email = data.delete(:primary_email).try(:to_s).try(:downcase)
        org_id = data.delete :organization_id
        data[:password_confirmation] ||= ''

        user = User.new data

        User.transaction do

          if data[:technical] && org_id.present?
            org = Organization.where(api_id: org_id).first
            user.memberships << Membership.new(user: user, organization: org)
          end

          authorize! user, :create

          if email.present? && email != current_otp_record.try(:organization_email).try(:address)
            authorize! user, :update_email
            user.primary_email = Email.where(address: email).first_or_initialize
            user.primary_email.user = user
          elsif current_otp_record.kind_of? Membership
            user.primary_email = current_otp_record.organization_email
            user.primary_email.user = user
            user.primary_email.active = true
          end

          create_record user do
            if current_otp_record.kind_of? Membership
              current_otp_record.user = user
              current_otp_record.save!
            end
          end
          # TODO: send registration e-mail
        end
      end

      get do
        authenticate
        authorize! User, :index

        rel = User.order 'name ASC'

        rel = paginated rel do |rel|
          if params[:search].present?
            term = "%#{params[:search].downcase}%"
            rel = rel.where 'LOWER(users.name) LIKE ?', term
          end

          rel = rel.where 'users.name = ?', params[:name].to_s if params[:name].present?
          rel
        end

        serialize load_resources(rel)
      end

      namespace '/:id' do
        before do
          authenticate!
        end

        helpers do
          def record
            @record ||= load_resource!(User.where(api_id: params[:id].to_s))
          end
        end

        get do
          authorize! record, :show
          serialize record
        end

        patch do
          authorize! record, :update

          User.transaction do

            updates = parse_user

            record.name = updates[:name] if updates.key? :name

            if updates.key?(:active) && !!updates[:active] != record.active
              authorize! record, :update_active
              record.active = !!updates[:active]
            end

            # FIXME: only allow to set primary email if among existing emails
            if updates.key?(:primary_email) && updates[:primary_email] != record.primary_email.address
              authorize! record, :update_email
              record.primary_email = Email.where(address: updates[:primary_email].to_s.downcase).first_or_initialize if updates.key?(:primary_email) && updates[:primary_email] != record.primary_email.try(:address)
              record.primary_email.user = record
            end

            if updates.key? :password
              authorize! record, :update_password
              record.password = updates[:password]
              record.password_confirmation = updates[:password_confirmation] || ''
            end

            update_record record
          end
        end

        delete do
          authorize! record, :destroy
          record.destroy
          status 204
          nil
        end
      end
    end
  end
end
