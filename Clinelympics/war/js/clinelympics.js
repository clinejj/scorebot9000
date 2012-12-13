// JavaScript Document
$('#addEventForm').submit(function(event) {
	event.preventDefault();
	var a=$('#addEventForm').serialize();
	addForm(a, $('#eventType').val());
});

$('#addPlayerForm').submit(function(event) {
	event.preventDefault();
	var a=$('#addPlayerForm').serialize();
	addForm(a, $('#playerType').val());
});

$('#addGameForm').submit(function(event) {
	event.preventDefault();
	var a=$('#addGameForm').serialize();
	addForm(a, $('#gameType').val());
});

$('#addScoreForm').submit(function(event) {
	event.preventDefault();
	var a=$('#addScoreForm').serialize();
	addForm(a, $('#scoreType').val());
});

$('#addNameForm').submit(function(event) {
	event.preventDefault();
	var a=$('#addNameForm').serialize();
	addForm(a, $('#nameType').val());
});

function addForm(params, type) {
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
				$('#'+type+'_response').html('<p class="text-warning">'+res+'</p>');
			});
		}
	});
}

$('#textForm').submit(function(event) {
	event.preventDefault();

	var a=$('#textForm').serialize();
	$.ajax({
		type: 'post',
		url: '/inbound',
		data: a,
		dataType: 'text',
		success: function(res) {
			alert(res)
		}
	});
});