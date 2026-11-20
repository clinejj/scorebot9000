$('#eventMedalIn').tooltip({
	animation: true,
	trigger: 'focus'
});

$('#teamRadio').tooltip({
	animation: true,
	trigger: 'hover'
});

$('#playerRadio').tooltip({
	animation: true,
	trigger: 'hover'
});

$("tr").hover(
	function() {
		var id = $(this).attr("id");
		if (id !== "header") {
			id = id.replace(" ","_");
			$("#del_" + id).show();
		}
	}, function() {
		var id = $(this).attr("id");
		if (id !== "header") {
			id = id.replace(" ","_");
			$("#del_" + id).hide();
		}
	}
);

function unBindTable() {
	$("tr").unbind('mouseenter mouseleave');
	$("tr").hover(
		function() {
			var id = $(this).attr("id");
			if (id !== "header") {
				id = id.replace(" ","_");
				$("#del_" + id).show();
			}
		}, function() {
			var id = $(this).attr("id");
			if (id !== "header") {
				id = id.replace(" ","_");
				$("#del_" + id).hide();
			}
		}
	);
}