# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  
  def torrent_dl(torrent)
    url_for(:controller => 'torrent', :action => 'download', :id => torrent.id, :filename => torrent.filename)
  end

  def torrent_dl_passkey(torrent, passkey)
    url_for(:only_path => false, :controller => 'torrent', :action => 'download', :id => torrent.id, :filename => torrent.filename, :passkey => passkey)
  end
  
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
  
  def toggle_div(div_id, show_text, hide_text,initially_present_show_link=true)
    show_link_id = "#{div_id}_show_link"
    hide_link_id = "#{div_id}_hide_link"
    return "<a id=\"#{show_link_id}\" href=\"#\" onclick=\"$('#{show_link_id}').hide();$('#{div_id}').show();$('#{hide_link_id}').show();return(false);\" #{ initially_present_show_link ? "" : "style=\"display:none;\""}>#{show_text}</a>" +
    "<a id=\"#{hide_link_id}\" href=\"#\" onclick=\"$('#{hide_link_id}').hide();$('#{show_link_id}').show();$('#{div_id}').hide();return(false);\" #{ initially_present_show_link ? "style=\"display:none;\"" : ''}>#{hide_text}</a>";
  end
  
  def hidden
    "style=\"display:none;\""
  end
  
end
