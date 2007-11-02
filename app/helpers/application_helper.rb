# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper

  def navclass(controller, action, except = '')
    cmatch = (@controller_name == controller)
    if cmatch && (action == '*') && !except.include?(@action_name)
      return 'current_page_item' 
    end
    if cmatch && (@action_name == action)
      return 'current_page_item' 
    end
    return 'page_item'
  end
  
end
