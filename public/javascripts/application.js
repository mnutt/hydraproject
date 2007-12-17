
function showFileList(id) {
  html = $('file_list').innerHTML;
  if (html != '') {
    toggleOn('file_list');
    hideFileListLink();
    return false;
  }
  url = '/torrent/file_list/' + id;
  new Ajax.Updater('file_list', url, {asynchronous:true, evalScripts:true, onComplete: hideFileListLink});
  return false;
}

function hideFileListLink() {
  toggleOff('show_files_link');
  toggleOn('hide_files_link');
}

function toggleFileListOff() {
  toggleOff('file_list');
  toggleOn('show_files_link');
  toggleOff('hide_files_link');
}

function toggleDiv(divid) {
  if(document.getElementById(divid).style.display == 'none'){
    document.getElementById(divid).style.display = 'block';
    Element.show(divid);
  }else{
    document.getElementById(divid).style.display = 'none';
    Element.hide(divid);
  }
}

function toggleOn(divid) {
  if(document.getElementById(divid).style.display == 'none'){
    document.getElementById(divid).style.display = 'block';
  }
}

function toggleOff(divid) {
  $(divid).style.display = 'none';
}