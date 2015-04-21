# Copyright (c) 2015 42 inside
# Copyright (c) 2012-2014 Lotaris SA
#
# This file is part of Probe Dock.
#
# Probe Dock is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Probe Dock is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Probe Dock.  If not, see <http://www.gnu.org/licenses/>.
module ApiAuthenticationHelper

  def auth_token_from_params
    params[:authToken]
  end

  def auth_token_from_header
    if m = headers['Authorization'].try(:match, /\ABearer (.+)\Z/)
      m[1]
    else
      nil
    end
  end

  def authenticate!
    @auth_token = auth_token_from_header || auth_token_from_params
    raise ProbeDock::Errors::Unauthorized.new 'Missing credentials' if @auth_token.blank?

    # TODO: use another secret for signing auth tokens
    begin
      @auth_claims = JSON::JWT.decode(@auth_token, Rails.application.secrets.secret_key_base)
    rescue JSON::JWT::Exception
      raise ProbeDock::Errors::Unauthorized.new 'Invalid credentials'
    end
  end

  def current_user
    @current_user ||= User.joins(:emails).where(emails: { address: @auth_claims['iss'] }).includes(memberships: :organization).first!
  end
end
