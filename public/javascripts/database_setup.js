function changeAdapterType() {
  if($('db_adapter').value == "sqlite3") {
    $$('.no_sqlite')[0].hide();
    $('db_database').value = "db/hydra.db";
  } else {
    $$('.no_sqlite')[0].show();
    $('db_database').value = "hydra";
  }
}

document.observe("dom:loaded", function() {
  $('db_adapter').observe('change', changeAdapterType);
  changeAdapterType();
});