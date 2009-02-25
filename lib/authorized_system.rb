module AuthorizedSystem
  ROLES = [:anonymous, :user, :admin]
  ACTIONS = [:view, :download, :upload, :web_seed]

  protected
    def authorize(action, user)
      role = (user.nil?) ? :anonymous : user.role
      C[:permissions][role].include?(action) rescue false
    end

    def authorize_view
      authorize(:view, current_user) || access_denied
    end

    def authorize_download
      authorize(:download, current_user) || access_denied
    end

    def authorize_upload
      authorize(:upload, current_user) || access_denied
    end

    def authorize_web_seed
      authorize(:upload, current_user) || access_denied
    end
end
