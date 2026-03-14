import Foundation

// MARK: - Smart List

enum SmartList: String, CaseIterable, Identifiable, Codable, Hashable {
    case inbox, today, upcoming, calendar, anytime, logbook, trash

    var id: String { rawValue }

    var label: String {
        switch self {
        case .inbox: "My Slay List"
        case .today: "Today"
        case .upcoming: "Upcoming"
        case .calendar: "Calendar"
        case .anytime: "All Tasks"
        case .logbook: "Slayed Tasks"
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

struct Quote: Identifiable, Equatable {
    let id = UUID()
    let text: String

    static func == (lhs: Quote, rhs: Quote) -> Bool {
        lhs.id == rhs.id
    }
}

let inspirationalQuotes: [String] = [
    // Gurl energy
    "Gurl, you just ATE that task up!",
    "Gurl... the way you just handled that? Iconic.",
    "Gurl, productivity looks STUNNING on you!",
    "Gurl, you are literally on fire right now!",
    "Gurl, crown is SECURE. Keep going!",
    "Gurl, that was smooth. Real smooth.",
    "Gurl, you're in your era and it SHOWS!",
    "Gurl, the vibes are immaculate today!",
    "Gurl, you're not just doing it \u{2014} you're SERVING!",
    "Gurl, pop the champagne \u{2014} another one down!",
    "Gurl, you snapped! Absolutely snapped!",
    "Gurl, that's giving boss energy and I'm here for it!",
    "Gurl, you're built different and tasks know it!",
    "Gurl, you just cleared that like a RUNWAY!",
    "Gurl, not you being this productive \u{2014} obsessed!",
    "Gurl, that task never stood a chance!",
    "Gurl, you're a diamond doing diamond things!",
    "Gurl, you just gave EXECUTIVE realness!",
    "Gurl, the way you move through tasks? ART.",
    "Gurl, they're gonna write songs about this productivity.",
    "Gurl, you're giving main character AND director energy!",
    "Gurl, your work ethic just entered the chat \u{2014} and it's SERVING.",
    "Gurl, even your tasks are impressed with you right now.",
    "Gurl, that focus? LASER. That execution? FLAWLESS.",
    "Gurl, you just speed-ran that like a PRO!",
    "Gurl, the productivity fairy just crowned you QUEEN.",

    // She believed she could
    "She believed she could, so she did.",
    "She said she'd get it done, and look at her GO!",
    "She's not lucky, she's DISCIPLINED.",
    "She didn't wait for motivation \u{2014} she created it.",
    "She makes hard things look EASY.",
    "She woke up and chose productivity.",
    "She's writing her success story, one task at a time.",
    "She has the receipts \u{2014} and they all say DONE.",

    // Main character energy
    "Main character energy right there!",
    "This is YOUR movie and you're nailing every scene.",
    "Plot twist: she was unstoppable all along.",
    "Someone call the press \u{2014} a queen is being productive.",
    "The script says you WIN. Every single time.",
    "You're not an extra in anyone's story \u{2014} you're the LEAD.",
    "Main characters don't procrastinate. They DELIVER.",
    "If productivity were a movie, you'd be the whole CAST.",

    // Pink & fabulous
    "Think pink, think DONE.",
    "Life in pink hits different when tasks are done.",
    "Pink productivity? She invented it.",
    "Everything she touches turns to pink gold.",
    "Rose-tinted and results-oriented \u{2014} that's the vibe.",
    "Tickled pink because that task is FINISHED.",
    "In a world of grey to-do lists, she chose PINK.",
    "Pink isn't just a colour \u{2014} it's a productivity superpower.",
    "Painting the town pink, one completed task at a time.",
    "Roses are pink, violets are too, that task is done, and so are you!",

    // Dream life vibes
    "Building your dream life, one task at a time.",
    "Your dream life has excellent task management.",
    "Another beautiful day, another task DEMOLISHED.",
    "Work hard now, Malibu later.",
    "She runs her life like she runs her dream house \u{2014} flawlessly.",
    "The dream house isn't gonna build itself \u{2014} oh wait, you just DID.",
    "Living the dream means doing the work, and you're CRUSHING it.",
    "Dream big, slay tasks, repeat.",
    "Every task done brings you closer to the penthouse.",
    "Your future self is THANKING you right now.",

    // Boss / career
    "She can be anything \u{2014} and right now she's being PRODUCTIVE.",
    "CEO of getting things done.",
    "Pilot, doctor, astronaut, and now? Task-slayer.",
    "The science is clear: you're incredible.",
    "Her productivity graph only goes UP.",
    "She shoots for the moon \u{2014} and finishes her tasks first.",
    "Ambition + action = YOU right now.",
    "That's not a to-do list. That's a BUSINESS PLAN.",
    "Board meeting energy. Tasks don't stand a chance.",
    "Promoting yourself to Chief Task Slayer, effective IMMEDIATELY.",
    "Your LinkedIn should just say 'Gets. Things. Done.'",
    "Corner office energy. No \u{2014} WHOLE BUILDING energy.",
    "When she puts her mind to it, mountains MOVE.",

    // Slay / serve / eat
    "Slay the day, slay the tasks, slay everything.",
    "Star behaviour, honestly.",
    "She really said 'let them eat cake' and SERVED.",
    "Too glam to give up, too fierce to slow down.",
    "You didn't just finish that \u{2014} you DEMOLISHED it.",
    "You're not just eating, you're having a FEAST.",
    "That task? DEVOURED. Next!",
    "She ate and left NO crumbs.",
    "Serving looks AND productivity? Greedy (and we LOVE it).",
    "She said 'bon app\u{00E9}tit' and ate every single task.",
    "That was a five-star performance, chef's kiss!",

    // Self-love & growth
    "Self-love is finishing your to-do list.",
    "Growing and glowing, one task at a time.",
    "Every task done is a seed planted for your future self.",
    "Bloom where you're planted \u{2014} and bloom HARD.",
    "Being kind to yourself includes getting stuff DONE.",
    "Productive AND at peace? That's the energy.",
    "Pressure makes diamonds, and you're shining.",
    "Healing AND hustling? The duality of a QUEEN.",
    "Self-care is crossing things off your list. Periodt.",
    "You're not just doing tasks, you're nurturing your GROWTH.",
    "Watering your goals like the garden they are.",
    "Inner peace AND a clear to-do list? That's LUXURY.",

    // Motivation / keep going
    "Unstoppable. Keep that momentum.",
    "You're on a ROLL and nobody can stop you.",
    "That energy? ELECTRIC. Keep it coming.",
    "Gold medal in getting things done.",
    "She runs the world AND her to-do list.",
    "She's not on another level \u{2014} she's on another PLANET.",
    "Change the world? She's starting with her tasks.",
    "She came, she saw, she CHECKED IT OFF.",
    "The momentum is REAL. Don't stop now!",
    "You're a FORCE and forces don't rest.",
    "Keep going \u{2014} the finish line is rolling out the red carpet for you.",
    "That's called VELOCITY, baby. Pure speed.",
    "One more down. You're on a TEAR.",
    "This is what winning looks like.",
    "The vibe right now? Absolutely RELENTLESS.",

    // Confidence
    "Lipstick on, tasks done, world conquered.",
    "She does it all \u{2014} and in heels.",
    "Dear tasks, consider yourselves HANDLED.",
    "She deserves flowers for this productivity.",
    "Confetti-worthy performance. Every. Single. Time.",
    "Pop the bottles \u{2014} she's on a STREAK.",
    "Mirror mirror on the wall, who slays tasks best of all? YOU.",
    "Confidence level: 'just cleared my to-do list'.",
    "Walking into the next task like she owns the ROOM.",
    "Hair flip. Task done. NEXT.",
    "She didn't even flinch. Just handled it.",

    // Fun & sassy
    "Task who? Never heard of her \u{2014} she's DONE.",
    "Peace out, task. You've been handled.",
    "Her to-do list is shaking right now.",
    "Not her being THIS efficient \u{2014} the audacity.",
    "Tasks getting done faster than delivery.",
    "She turned her to-do list into a TA-DA list.",
    "On fire and not even breaking a sweat.",
    "She finishes tasks like she's on a dance floor \u{2014} with FLAIR.",
    "That task was a piece of cake \u{2014} and she ATE.",
    "The forecast says... more wins in your future.",
    "Riding the productivity wave like a QUEEN.",
    "Alexa, play 'Flawless' by Beyonc\u{00E9}.",
    "Tasks are dropping like flies and she's not even trying.",
    "That was faster than her morning coffee order.",
    "She collects completed tasks like she collects compliments \u{2014} EFFORTLESSLY.",
    "That task just got a one-way ticket to DONE town.",
    "BRB, adding 'professional task destroyer' to the r\u{00E9}sum\u{00E9}.",
    "She's speed-running life and WINNING.",
    "Plot twist: the task was the easy part.",
    "Somebody stop her \u{2014} actually, DON'T.",
    "If tasks had feelings, they'd be INTIMIDATED.",
    "The to-do list called. It surrendered.",

    // Late night / grind
    "Moonlight hustle? She makes it look glamorous.",
    "Sleep can wait, she's in her ZONE.",
    "Fueled by coffee and pure determination.",
    "Late-night grind? More like late-night GLOW.",
    "The stars are out and so is her A-GAME.",
    "Night owl energy, but make it productive.",

    // Relaxation earned
    "Beach vibes are EARNED and you just earned them.",
    "Spa day energy. You deserve it after that.",
    "Treat yourself \u{2014} you've EARNED it, queen.",
    "The couch is calling and you can ANSWER now.",
    "Netflix won't judge \u{2014} you've done the WORK.",
    "Run yourself a bath. That was LEGENDARY.",
    "You've earned a nap, a snack, and a standing ovation.",

    // Empowerment
    "She's not just breaking glass ceilings \u{2014} she's smashing tasks.",
    "Beauty AND brains AND productivity? The whole package.",
    "When she shines, even her to-do list sparkles.",
    "Strong women finish their tasks.",
    "You're not just getting things done \u{2014} you're changing the game.",
    "Living her truth AND crossing things off her list.",
    "Flexing on her tasks like it's arm day.",
    "She writes her own rules AND her own to-do list.",
    "Behind every great woman is a CONQUERED to-do list.",
    "She's the energy the world needs right now.",
    "Queens don't quit. They COMPLETE.",

    // Ken rewards
    "Ken just called \u{2014} he says you deserve a kiss for that one.",
    "Ken dropped his surfboard because he was too busy watching you SLAY.",
    "Ken is writing you a love letter about your productivity right now.",
    "Ken says: 'I'm just Ken, but YOU are extraordinary.'",
    "Ken wants you to know he's never been more impressed.",
    "Even Ken couldn't look this good being productive.",
    "Ken is blushing. That's how good you just did.",
    "Ken cancelled his beach day to applaud you. Standing ovation.",
    "Ken asked if you're single because WOW, that was impressive.",
    "Ken just made you a smoothie. You earned it, queen.",
    "Ken is literally fanning himself \u{2014} you're on FIRE.",
    "Plot twist: Ken's dream job is being YOUR hype man.",
    "Ken just updated his bio to 'fan of YOUR productivity'.",
    "Ken tried to keep up with you. He couldn't.",
    "Ken wants to be you when he grows up. Honestly.",
    "Ken just ordered flowers for you. The card says 'WOW'.",
    "Ken rehearsed a speech about how amazing you are. He's nervous.",
    "Ken would write a book about you but the chapters would all say SLAY.",

    // Iconic references
    "That's so fetch \u{2014} and by fetch, I mean FINISHED.",
    "In the words of Rihanna: work work work work work DONE.",
    "Legally productive. Elle Woods would be PROUD.",
    "You're the Beyonc\u{00E9} of to-do lists.",
    "Channel your inner Oprah: YOU get a checkmark! And YOU!",
    "Marie Kondo would say this productivity sparks JOY.",
    "Coco Chanel said be irreplaceable. You said be UNSTOPPABLE.",
    "Audrey Hepburn would approve of this elegance AND efficiency.",
    "She's got the Midas touch but make it PINK.",

    // Cosmic / magical
    "The universe just high-fived you for that one.",
    "Stars aligned and tasks got SLAYED.",
    "That was pure MAGIC and you're the magician.",
    "Manifesting? No \u{2014} she's EXECUTING.",
    "The moon is full and so is her done list.",
    "She's got the energy of a thousand suns right now.",
    "Fairy godmother energy \u{2014} turning tasks into DONE.",
    "She cast a productivity spell and it WORKED.",
    "The zodiac says: you're absolutely killing it today.",

    // Short & punchy
    "BOOM. Done.",
    "Another one bites the dust!",
    "Check. MATE.",
    "Mic drop moment.",
    "And just like THAT \u{2014} done.",
    "Easy work for a QUEEN.",
    "Next!",
    "Smooth operator strikes again.",
    "Nailed it. Absolutely NAILED it.",
    "Victory is YOURS.",
    "That's how it's DONE.",
    "Clean sweep. BEAUTIFUL.",
    "Flawless execution!",
    "Poetry in motion.",
    "Chef's kiss. PERFECTION.",
    "Crushed it!",
    "Touchdown! She SCORES!",
    "Nothing but NET.",
    "SLAYED!",
    "Winner winner, task-free dinner!",
]
