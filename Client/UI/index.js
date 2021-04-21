var timeout_hud;
var interval_score;
var total_score = 0;
var total_score_current = 0;

Events.Subscribe("AddScore", function(score, type_id, label, use_current) {
    total_score += score;

    // Displays all DOM elements
    DisplayHUD();

    // If should increment current score item instead of creating a new one
    if (use_current)
    {
        // Try to find if there is already a score item
        let score_feed_item_value = $(`.${type_id} .score_value_item`);

        // If a score item is found, then update it and return, otherwise it will keep on and will create a new one
        if (score_feed_item_value.length)
        {
            score_feed_item_value.html(parseInt(score_feed_item_value.html()) + score);
            return;
        }
    }

    // Create a new score item and prepend it on the list
    let score_feed_item = $(`<span class='score_feed_item ${type_id}'>${label} +<span class='score_value_item'>${score}</span></span>`);
    $("#score_feed").prepend(score_feed_item);
});

Events.Subscribe("AddKill", function(name, is_headshot) {
    // Adds 20 score for killing
    total_score += 20;

    // Displays the killed name
    $("#death_name").html(`${name} +20`);

    // If it was headshot, displays the red skull, otherwise displays the white
    let death_count_white = $(`<span class='death_count ${is_headshot ? "death_count_red" : "death_count_white"}'>`);
    $("#death_counts").prepend(death_count_white);

    // Displays all DOM elements
    DisplayHUD();
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
    let interp_pace = Math.max((total_score - total_score_current) / 2, 1);

    total_score_current = parseInt(Math.min(total_score, total_score_current + interp_pace));
    $("#total_score").html(total_score_current);
}