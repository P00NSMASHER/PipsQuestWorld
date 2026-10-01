--!strict
-- Server-only class activity catalog. Answer keys never enter ReplicatedStorage.

return {
    {
        id = "math-linear-1",
        subject = "Math",
        difficulty = 1,
        prompt = "Solve for x: x + 7 = 12.",
        choices = { "3", "5", "7", "19" },
        correctIndex = 2,
        hint = "Undo adding 7 by subtracting 7 from 12.",
        explanation = "x = 5 because 5 + 7 = 12.",
    },
    {
        id = "ela-main-idea-1",
        subject = "ELA",
        difficulty = 1,
        prompt = "Which choice best describes a paragraph's main idea?",
        choices = {
            "Its central point",
            "One small detail",
            "The final word",
            "A character's name"
        },
        correctIndex = 1,
        hint = "Look for the idea that the whole paragraph supports.",
        explanation = "The main idea is the paragraph's central point.",
    },
    {
        id = "science-cell-1",
        subject = "Science",
        difficulty = 1,
        prompt = "Which structure controls what enters and leaves a cell?",
        choices = { "Cell membrane", "Nucleus", "Ribosome", "Chromosome" },
        correctIndex = 1,
        hint = "Think about the thin boundary around the cell.",
        explanation = "The cell membrane regulates what enters and leaves the cell.",
    },
    {
        id = "social-civics-1",
        subject = "SocialStudies",
        difficulty = 1,
        prompt = "Which branch of government interprets laws?",
        choices = { "Executive", "Judicial", "Legislative", "Local" },
        correctIndex = 2,
        hint = "Courts belong to this branch.",
        explanation = "The judicial branch interprets laws.",
    },
}
