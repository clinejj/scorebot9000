$('#addEventForm').live('submit', (function(event) {
	event.preventDefault();
	var a=$('#addEventForm').serialize();
	if (a.indexOf("archived=") == -1) {
		a = a + "&archived=false";
	}
	if (a.indexOf("active=") == -1) {
		a = a + "&active=false";
	}
	if (a.indexOf("teams=") == -1) {
		a = a + "&teams=false";
	}
	editItems(a, $('#eventType').val(), "add");
	
}));

$('#addPlayerForm').live('submit', (function(event) {
	event.preventDefault();
	var a=$('#addPlayerForm').serialize();
	editItems(a, $('#playerType').val(), "add");
}));

$('#addGameForm').live('submit', (function(event) {
	event.preventDefault();
	var a=$('#addGameForm').serialize();
	editItems(a, $('#gameType').val(), "add");
}));

$('#addScoreForm').live('submit', (function(event) {
	event.preventDefault();
	var a=$('#addScoreForm').serialize();
	editItems(a, $('#scoreType').val(), "add");
}));

$('#addNameForm').live('submit', (function(event) {
	event.preventDefault();
	var a=$('#addNameForm').serialize();
	editItems(a, $('#nameType').val(), "add");
}));

function deleteItem(itemval, type) {
	itemval = itemval + "&type=" + type;
	editItems(itemval, type, "delete");
};

function editItems(params, type, method) {
	params = params + "&method=" + method;
	$.ajax({
		type: 'post',
		url: '/add',
		data: params,
		dataType: 'text',
		beforeSend: function(xhr) {xhr.setRequestHeader('userEmail',$('#userEmail').val())},
		success: function(res) {
			//alert(res);
			$.get('/admin/'+type+'s.jsp').success(function(data) {
				$('#'+type).html(data);
				var newHTML = '<div class=" alert ';
				var resArgs = res.split("err: ");
				var btnHTML = '<button type="button" class="close" data-dismiss="alert">&times;</button>';
				if (resArgs.length > 1) {
					newHTML = newHTML + 'alert-error">' + btnHTML + resArgs[1] + '</div>';
				} else {
					if (type === "event") {
						if (res.indexOf("&&") !== -1) {
							var cIDs = res.split("&&");
							if (parseInt(cIDs[1]) == -1) {
								$('#current_event').html("N/A");
							} else {
								$('#current_event').html(cIDs[1]);
							}
							res = cIDs[0];
							$.get('/admin/names.jsp').success(function(newdata) {
								$('#name').html(newdata);
							});
						}
					}
					if (res.indexOf("update") !== -1) {
						newHTML = newHTML + 'alert-info">' + btnHTML + res + '</div>';
					} else {
						newHTML = newHTML + 'alert-success">' + btnHTML + res + '</div>';
					}
				}
				$('#'+type+'_response').html(newHTML);
			});
		}
	});
}

$('#textForm').live('submit', (function(event) {
	event.preventDefault();

	var a=$('#textForm').serialize();
	$.ajax({
		type: 'post',
		url: '/inbound',
		data: a,
		dataType: 'text',
		success: function(res) {
			$.get('/admin/texts.jsp').success(function(data) {
				$('#text').html(data);
				$('#text_response').html('<div class=" alert alert-info"><button type="button" class="close" data-dismiss="alert">&times;</button>'+res+'</div>');
				if (res.indexOf("Welcome to team") !== -1) {
					$.get('/admin/names.jsp').success(function(newdata) {
						$('#name').html(newdata);
					});
					$.get('/admin/players.jsp').success(function(newdata) {
						$('#player').html(newdata);
					});
				}
			});
		}
	});
}));