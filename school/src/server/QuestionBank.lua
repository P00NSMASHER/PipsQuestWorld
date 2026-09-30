local QuestionBank = {}

local BANK = {
    ["Life Skills"] = {
        {
            id = "life-001",
            prompt = "What is the best first step when you do not understand directions?",
            choices = { "Guess and hope", "Ask a clear question", "Quit the activity", "Copy someone silently" },
            correctIndex = 2,
            hint = "Think about the choice that helps you get useful information.",
            explanation = "A clear question helps you understand what to do next.",
        },
        {
            id = "life-002",
            prompt = "Which choice shows good teamwork?",
            choices = { "Taking every turn", "Listening and sharing turns", "Ignoring the group", "Changing the rules alone" },
            correctIndex = 2,
            hint = "Good teams make space for everyone.",
            explanation = "Listening and sharing turns helps a group work together.",
        },
    },
    Math = {
        {
            id = "math-001",
            prompt = "What is 7 + 5?",
            choices = { "10", "11", "12", "13" },
            correctIndex = 3,
            hint = "Start at 7 and count forward 5 more.",
            explanation = "Addition combines two amounts into one total.",
        },
        {
            id = "math-002",
            prompt = "Which number is even?",
            choices = { "7", "9", "12", "15" },
            correctIndex = 3,
            hint = "An even number can be split into two equal whole-number groups.",
            explanation = "Even numbers divide into pairs with nothing left over.",
        },
        {
            id = "math-003",
            prompt = "What is 14 - 6?",
            choices = { "6", "7", "8", "9" },
            correctIndex = 3,
            hint = "Count backward six steps from 14.",
            explanation = "Subtraction tells how much remains after taking some away.",
        },
    },
    ELA = {
        {
            id = "ela-001",
            prompt = "Which word is a noun?",
            choices = { "quickly", "school", "bright", "jump" },
            correctIndex = 2,
            hint = "A noun names a person, place, thing, or idea.",
            explanation = "A place name is a noun.",
        },
        {
            id = "ela-002",
            prompt = "A story takes place at a beach during a storm. What does 'setting' describe?",
            choices = { "Where and when the story happens", "The lesson only", "The title", "The author's name" },
            correctIndex = 1,
            hint = "Setting answers where and when.",
            explanation = "The setting tells the time and place of a story.",
        },
        {
            id = "ela-003",
            prompt = "Which word has a short-a sound?",
            choices = { "cake", "cat", "rain", "team" },
            correctIndex = 2,
            hint = "Say each word slowly and listen to the vowel sound.",
            explanation = "Short-vowel sounds are identified by how the vowel sounds in the word.",
        },
    },
    Science = {
        {
            id = "sci-001",
            prompt = "Which part of a plant usually takes in water from soil?",
            choices = { "Roots", "Flower", "Fruit", "Seed coat" },
            correctIndex = 1,
            hint = "Think about the plant part that is usually underground.",
            explanation = "Roots absorb water and help anchor the plant.",
        },
        {
            id = "sci-002",
            prompt = "Which object is most likely attracted to a magnet?",
            choices = { "Wooden block", "Iron nail", "Rubber band", "Paper cup" },
            correctIndex = 2,
            hint = "Magnets attract certain metals.",
            explanation = "Iron is a magnetic material.",
        },
        {
            id = "sci-003",
            prompt = "Water changing from liquid to vapor is called what?",
            choices = { "Freezing", "Melting", "Evaporation", "Condensation" },
            correctIndex = 3,
            hint = "Think about a puddle slowly disappearing on a warm day.",
            explanation = "Evaporation is a change from liquid water into water vapor.",
        },
    },
    ["Social Studies"] = {
        {
            id = "ss-001",
            prompt = "What does a map key help you understand?",
            choices = { "What map symbols mean", "How old the map is", "Who owns the map", "The weather tomorrow" },
            correctIndex = 1,
            hint = "Look for the part of a map that explains symbols and colors.",
            explanation = "A map key or legend explains the meaning of symbols.",
        },
        {
            id = "ss-002",
            prompt = "Which is an example of a community service?",
            choices = { "Littering", "Helping clean a public park", "Breaking a sign", "Blocking a sidewalk" },
            correctIndex = 2,
            hint = "Community service helps other people or shared places.",
            explanation = "Caring for shared public spaces is a form of community service.",
        },
    },
    Health = {
        {
            id = "health-001",
            prompt = "What is a good reason to warm up before active exercise?",
            choices = { "Prepare the body to move", "Make shoes heavier", "Avoid drinking water", "Skip practice" },
            correctIndex = 1,
            hint = "Think about getting muscles and joints ready for activity.",
            explanation = "A warm-up gradually prepares the body for harder movement.",
        },
        {
            id = "health-002",
            prompt = "Which habit supports healthy activity?",
            choices = { "Never resting", "Drinking water", "Ignoring pain", "Skipping meals every day" },
            correctIndex = 2,
            hint = "Active bodies need hydration.",
            explanation = "Water supports normal body function during activity.",
        },
    },
}

local lastBySubject = {}

function QuestionBank.getRandom(subject, randomObject)
    local subjectBank = BANK[subject]
    if not subjectBank or #subjectBank == 0 then
        return nil
    end

    if #subjectBank == 1 then
        return subjectBank[1]
    end

    local previousId = lastBySubject[subject]
    local candidate
    for _ = 1, 6 do
        candidate = subjectBank[randomObject:NextInteger(1, #subjectBank)]
        if candidate.id ~= previousId then
            break
        end
    end

    lastBySubject[subject] = candidate.id
    return candidate
end

return QuestionBank
