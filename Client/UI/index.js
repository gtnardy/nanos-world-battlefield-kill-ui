var timeout_hud;
var interval_score;
var total_score = 0;
var total_score_current = 0;


function CalculateAngleBetweenPoints(x0, y0, x1, y1) {
	return Math.atan2(y1 - y0, x1 - x0) * 180 / Math.PI;
}

Events.Subscribe("UpdateDamageIndicator", function(id, enable, posX, posY) {
	let element = $(`#${id}`);

	if (enable) {
		if (!element.length) {
			element = $(`<span id='${id}' class='damage_indicator'>`);
			$("#damage_indicators").append(element);
		}
		
		let angle = 0;
		if (posX == -1 && posY == -1) {
			angle = 180;
		} else {
			const screen_width_center = window.innerWidth / 2;
			const screen_height_center = window.innerHeight - window.innerHeight / 3;
		
			angle = CalculateAngleBetweenPoints(screen_width_center, screen_height_center, posX, posY) + 90;
		}

		element.css("transform", `translate(-50%, -50%) rotate(${angle}deg)`);
	} else {
		if (element.length)
			element.fadeOut(500, function() { $(this).remove(); });
	}
});

Events.Subscribe("AddScore", function(score, type_id, label, use_current) {
	total_score += score;

	// Displays all DOM elements
	DisplayHUD();

	// If should increment current score item instead of creating a new one
	if (use_current)
	{
		// Try to find if there is already a score item
		const score_feed_item_value = $(`.${type_id} .score_value_item`);

		// If a score item is found, then update it and return, otherwise it will keep on and will create a new one
		if (score_feed_item_value.length)
		{
			score_feed_item_value.html(parseInt(score_feed_item_value.html()) + score);
			return;
		}
	}

	// Create a new score item and prepend it on the list
	const score_feed_item = $(`<span class='score_feed_item ${type_id}'>${label} +<span class='score_value_item'>${score}</span></span>`);
	$("#score_feed").prepend(score_feed_item);
});

Events.Subscribe("AddKill", function(name, is_headshot, score) {
	// Adds score for killing
	total_score += score;

	// Displays the killed name
	$("#death_name").html(`${name} +${score}`);

	// If it was headshot, displays the red skull, otherwise displays the white
	const death_count_white = $(`<span class='death_count ${is_headshot ? "death_count_red" : "death_count_white"}'>`);
	$("#death_counts").prepend(death_count_white);

	// Displays all DOM elements
	DisplayHUD();
});

Events.Subscribe("AddKillNotification", function(dead_name, killer_name, is_headshot, is_suicide) {
	const kill_notification_item = $(`<span class='kill_notification'>`);

	if (!is_suicide) {
		const kill_notification_killer = $(`<span class='kill_notification_killer'>`);
		kill_notification_killer.html(killer_name);
		kill_notification_item.append(kill_notification_killer);
	}

	const kill_notification_action = $(`<span class='kill_notification_action'>`);
	kill_notification_action.html(is_suicide ? "suicided" : "killed");
	kill_notification_item.append(kill_notification_action);
	
	if (is_headshot) {
		const kill_notification_headshot = $(`<span class='kill_notification_headshot'>`);
		kill_notification_item.append(kill_notification_headshot);
	}
	
	const kill_notification_dead = $(`<span class='kill_notification_dead'>`);
	kill_notification_dead.html(dead_name);
	kill_notification_item.append(kill_notification_dead);

	$("#kill_notifications").prepend(kill_notification_item);

	// Destroys the entry after 10 seconds
	setTimeout(function(span) {
		span.remove();
	}, 10000, kill_notification_item);
});


// Resets all animations and displays the HUD, also resets the timers and creates a new one to hide it in 4 seconds
function DisplayHUD() {
	$("#death_counts").stop(true, true).show();
	$("#death_name").stop(true, true).show();
	$("#score_feed").stop(true, true).show();
	$("#total_score").stop(true, true).show();

	if (timeout_hud)
		clearTimeout(timeout_hud);

	timeout_hud = setTimeout(ResetHUD, 4000);

	if (interval_score)
		clearInterval(interval_score);

	interval_score = setInterval(UpdateHUD, 50);
}

// Resets the HUD, i.e. hides everything with animations and resets all data
function ResetHUD() {
	$("#death_counts").fadeOut(500, function() {
		$("#death_counts").html("");
	});

	$("#death_name").fadeOut(500, function() {
		$("#death_name").html("");

		$("#score_feed").fadeOut(500, function() { $("#score_feed").html(""); });
		$("#total_score").fadeOut(500);
	});

	clearInterval(interval_score);
	interval_score = null;

	timeout_hud = null;
	total_score = 0;
	total_score_current = 0;
}

// Updates the HUD, i.e. updates the current displayed score in the screen
function UpdateHUD() {
	const interp_pace = Math.max((total_score - total_score_current) / 2, 1);

	total_score_current = parseInt(Math.min(total_score, total_score_current + interp_pace));
	$("#total_score").html(total_score_current);
}
