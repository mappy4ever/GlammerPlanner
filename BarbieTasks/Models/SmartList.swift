import Foundation

// MARK: - Smart List

enum SmartList: String, CaseIterable, Identifiable, Codable, Hashable {
    case inbox, today, upcoming, calendar, anytime, logbook, trash

    var id: String { rawValue }

    var label: String {
        switch self {
        case .inbox: "Inbox"
        case .today: "Today"
        case .upcoming: "Upcoming"
        case .calendar: "Calendar"
        case .anytime: "All Tasks"
        case .logbook: "Logbook"
        case .trash: "Trash"
        }
    }

    var icon: String {
        switch self {
        case .inbox: "tray"
        case .today: "star"
        case .upcoming: "calendar.badge.clock"
        case .calendar: "calendar"
        case .anytime: "list.bullet"
        case .logbook: "book.closed"
        case .trash: "trash"
        }
    }

    var isEditable: Bool {
        self != .logbook && self != .trash && self != .calendar
    }

    static var primary: [SmartList] { [.inbox, .today, .upcoming, .calendar, .anytime] }
    static var secondary: [SmartList] { [.logbook, .trash] }
}

// MARK: - View Selection

enum ViewSelection: Hashable, Codable {
    case smartList(SmartList)
    case project(UUID)
    case tag(UUID)
    case savedFilter(UUID)
    case stats
}

// MARK: - Sort

enum SortOption: String, CaseIterable, Identifiable, Codable {
    case manual, dueDate, priority, alphabetical, newest

    var id: String { rawValue }

    var label: String {
        switch self {
        case .manual: "Manual"
        case .dueDate: "Due Date"
        case .priority: "Priority"
        case .alphabetical: "A\u{2013}Z"
        case .newest: "Newest"
        }
    }
}

// MARK: - Quote

struct Quote {
    let text: String
}

let inspirationalQuotes: [Quote] = [
    // Gurl energy
    Quote(text: "Gurl, you just ATE that task up!"),
    Quote(text: "Gurl... the way you just handled that? Iconic."),
    Quote(text: "Gurl, productivity looks STUNNING on you!"),
    Quote(text: "Gurl, you are literally on fire right now!"),
    Quote(text: "Gurl, crown is SECURE. Keep going!"),
    Quote(text: "Gurl, that was smooth. Real smooth."),
    Quote(text: "Gurl, you're in your era and it SHOWS!"),
    Quote(text: "Gurl, the vibes are immaculate today!"),
    Quote(text: "Gurl, you're not just doing it \u{2014} you're SERVING!"),
    Quote(text: "Gurl, pop the champagne \u{2014} another one down!"),
    Quote(text: "Gurl, you snapped! Absolutely snapped!"),
    Quote(text: "Gurl, that's giving boss energy and I'm here for it!"),
    Quote(text: "Gurl, you're built different and tasks know it!"),
    Quote(text: "Gurl, you just cleared that like a RUNWAY!"),
    Quote(text: "Gurl, not you being this productive \u{2014} obsessed!"),
    Quote(text: "Gurl, that task never stood a chance!"),
    Quote(text: "Gurl, you're a diamond doing diamond things!"),

    // She believed she could
    Quote(text: "She believed she could, so she did."),
    Quote(text: "She said she'd get it done, and look at her GO!"),
    Quote(text: "She's not lucky, she's DISCIPLINED."),

    // Main character energy
    Quote(text: "Main character energy right there!"),
    Quote(text: "This is YOUR movie and you're nailing every scene."),
    Quote(text: "Plot twist: she was unstoppable all along."),
    Quote(text: "Someone call the press \u{2014} a queen is being productive."),

    // Pink & fabulous
    Quote(text: "Think pink, think DONE."),
    Quote(text: "Life in pink hits different when tasks are done."),
    Quote(text: "Pink productivity? She invented it."),
    Quote(text: "Everything she touches turns to pink gold."),
    Quote(text: "Rose-tinted and results-oriented \u{2014} that's the vibe."),

    // Dream life vibes
    Quote(text: "Building your dream life, one task at a time."),
    Quote(text: "Your dream life has excellent task management."),
    Quote(text: "Another beautiful day, another task DEMOLISHED."),
    Quote(text: "Work hard now, Malibu later."),
    Quote(text: "She runs her life like she runs her dream house \u{2014} flawlessly."),

    // Boss / career
    Quote(text: "She can be anything \u{2014} and right now she's being PRODUCTIVE."),
    Quote(text: "CEO of getting things done."),
    Quote(text: "Pilot, doctor, astronaut, and now? Task-slayer."),
    Quote(text: "The science is clear: you're incredible."),
    Quote(text: "Her productivity graph only goes UP."),
    Quote(text: "She shoots for the moon \u{2014} and finishes her tasks first."),
    Quote(text: "Ambition + action = YOU right now."),

    // Slay / serve / eat
    Quote(text: "Slay the day, slay the tasks, slay everything."),
    Quote(text: "Star behaviour, honestly."),
    Quote(text: "She really said 'let them eat cake' and SERVED."),
    Quote(text: "Too glam to give up, too fierce to slow down."),
    Quote(text: "You didn't just finish that \u{2014} you DEMOLISHED it."),

    // Self-love & growth
    Quote(text: "Self-love is finishing your to-do list."),
    Quote(text: "Growing and glowing, one task at a time."),
    Quote(text: "Every task done is a seed planted for your future self."),
    Quote(text: "Bloom where you're planted \u{2014} and bloom HARD."),
    Quote(text: "Being kind to yourself includes getting stuff DONE."),
    Quote(text: "Productive AND at peace? That's the energy."),
    Quote(text: "Pressure makes diamonds, and you're shining."),

    // Motivation / keep going
    Quote(text: "Unstoppable. Keep that momentum."),
    Quote(text: "You're on a ROLL and nobody can stop you."),
    Quote(text: "That energy? ELECTRIC. Keep it coming."),
    Quote(text: "Gold medal in getting things done."),
    Quote(text: "She runs the world AND her to-do list."),
    Quote(text: "She's not on another level \u{2014} she's on another PLANET."),
    Quote(text: "Change the world? She's starting with her tasks."),
    Quote(text: "She came, she saw, she CHECKED IT OFF."),

    // Confidence
    Quote(text: "Lipstick on, tasks done, world conquered."),
    Quote(text: "She does it all \u{2014} and in heels."),
    Quote(text: "Dear tasks, consider yourselves HANDLED."),
    Quote(text: "She deserves flowers for this productivity."),
    Quote(text: "Confetti-worthy performance. Every. Single. Time."),
    Quote(text: "Pop the bottles \u{2014} she's on a STREAK."),

    // Fun & sassy
    Quote(text: "Task who? Never heard of her \u{2014} she's DONE."),
    Quote(text: "Peace out, task. You've been handled."),
    Quote(text: "Her to-do list is shaking right now."),
    Quote(text: "Not her being THIS efficient \u{2014} the audacity."),
    Quote(text: "Tasks getting done faster than delivery."),
    Quote(text: "She turned her to-do list into a TA-DA list."),
    Quote(text: "On fire and not even breaking a sweat."),
    Quote(text: "She finishes tasks like she's on a dance floor \u{2014} with FLAIR."),
    Quote(text: "That task was a piece of cake \u{2014} and she ATE."),
    Quote(text: "The forecast says... more wins in your future."),
    Quote(text: "Riding the productivity wave like a QUEEN."),

    // Late night / grind
    Quote(text: "Moonlight hustle? She makes it look glamorous."),
    Quote(text: "Sleep can wait, she's in her ZONE."),
    Quote(text: "Fueled by coffee and pure determination."),

    // Relaxation earned
    Quote(text: "Beach vibes are EARNED and you just earned them."),
    Quote(text: "Spa day energy. You deserve it after that."),
    Quote(text: "Treat yourself \u{2014} you've EARNED it, queen."),

    // Empowerment
    Quote(text: "She's not just breaking glass ceilings \u{2014} she's smashing tasks."),
    Quote(text: "Beauty AND brains AND productivity? The whole package."),
    Quote(text: "When she shines, even her to-do list sparkles."),
    Quote(text: "Strong women finish their tasks."),
    Quote(text: "You're not just getting things done \u{2014} you're changing the game."),
    Quote(text: "Living her truth AND crossing things off her list."),
    Quote(text: "Flexing on her tasks like it's arm day."),

    // Ken rewards
    Quote(text: "Ken just called \u{2014} he says you deserve a kiss for that one."),
    Quote(text: "Ken dropped his surfboard because he was too busy watching you SLAY."),
    Quote(text: "Ken is writing you a love letter about your productivity right now."),
    Quote(text: "Ken says: 'I'm just Ken, but YOU are extraordinary.'"),
    Quote(text: "Ken wants you to know he's never been more impressed."),
    Quote(text: "Even Ken couldn't look this good being productive."),
    Quote(text: "Ken is blushing. That's how good you just did."),
    Quote(text: "Ken cancelled his beach day to applaud you. Standing ovation."),
    Quote(text: "Ken asked if you're single because WOW, that was impressive."),
    Quote(text: "Ken just made you a smoothie. You earned it, queen."),
    Quote(text: "Ken is literally fanning himself \u{2014} you're on FIRE."),
    Quote(text: "Plot twist: Ken's dream job is being YOUR hype man."),
]
