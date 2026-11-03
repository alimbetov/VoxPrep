package io.github.alimbetov.voxprep.backend.content.web;

import io.github.alimbetov.voxprep.backend.catalogue.domain.CatalogueCode;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

final class ContentMvcForms {

    private ContentMvcForms() {
    }

    static final class DraftForm {
        @NotNull
        @Min(0)
        private Long expectedVersion;

        @NotBlank
        @Size(max = 512)
        private String title;

        @NotBlank
        @Size(max = 512)
        private String subtitle;

        @NotBlank
        @Size(max = 4000)
        private String description;

        @NotBlank
        @Size(max = CatalogueCode.MAX_LENGTH)
        @Pattern(regexp = CatalogueCode.REGEXP)
        private String categoryCode;

        @NotBlank
        @Size(max = CatalogueCode.MAX_LENGTH)
        @Pattern(regexp = CatalogueCode.REGEXP)
        private String levelCode;

        @Min(1)
        private int minutes;

        private String skillCodes;

        @NotBlank
        @Pattern(regexp = "ACTIVE|INACTIVE")
        private String availability;

        @NotBlank
        private String bodyType;

        private String term;
        private String definition;
        private String partOfSpeech;
        private String examples;
        private String prompt;
        private String modelAnswer;
        private String keyPoints;
        private String sections;
        private String phrase;
        private String usage;
        private String transcript;
        private String segments;
        private String questionText;
        private String explanation;
        private String options;
        private String instructions;
        private Integer passingScorePercent;
        private String questionRevisionIds;

        public Long getExpectedVersion() { return expectedVersion; }
        public void setExpectedVersion(Long expectedVersion) { this.expectedVersion = expectedVersion; }
        public String getTitle() { return title; }
        public void setTitle(String title) { this.title = title; }
        public String getSubtitle() { return subtitle; }
        public void setSubtitle(String subtitle) { this.subtitle = subtitle; }
        public String getDescription() { return description; }
        public void setDescription(String description) { this.description = description; }
        public String getCategoryCode() { return categoryCode; }
        public void setCategoryCode(String categoryCode) { this.categoryCode = categoryCode; }
        public String getLevelCode() { return levelCode; }
        public void setLevelCode(String levelCode) { this.levelCode = levelCode; }
        public int getMinutes() { return minutes; }
        public void setMinutes(int minutes) { this.minutes = minutes; }
        public String getSkillCodes() { return skillCodes; }
        public void setSkillCodes(String skillCodes) { this.skillCodes = skillCodes; }
        public String getAvailability() { return availability; }
        public void setAvailability(String availability) { this.availability = availability; }
        public String getBodyType() { return bodyType; }
        public void setBodyType(String bodyType) { this.bodyType = bodyType; }
        public String getTerm() { return term; }
        public void setTerm(String term) { this.term = term; }
        public String getDefinition() { return definition; }
        public void setDefinition(String definition) { this.definition = definition; }
        public String getPartOfSpeech() { return partOfSpeech; }
        public void setPartOfSpeech(String partOfSpeech) { this.partOfSpeech = partOfSpeech; }
        public String getExamples() { return examples; }
        public void setExamples(String examples) { this.examples = examples; }
        public String getPrompt() { return prompt; }
        public void setPrompt(String prompt) { this.prompt = prompt; }
        public String getModelAnswer() { return modelAnswer; }
        public void setModelAnswer(String modelAnswer) { this.modelAnswer = modelAnswer; }
        public String getKeyPoints() { return keyPoints; }
        public void setKeyPoints(String keyPoints) { this.keyPoints = keyPoints; }
        public String getSections() { return sections; }
        public void setSections(String sections) { this.sections = sections; }
        public String getPhrase() { return phrase; }
        public void setPhrase(String phrase) { this.phrase = phrase; }
        public String getUsage() { return usage; }
        public void setUsage(String usage) { this.usage = usage; }
        public String getTranscript() { return transcript; }
        public void setTranscript(String transcript) { this.transcript = transcript; }
        public String getSegments() { return segments; }
        public void setSegments(String segments) { this.segments = segments; }
        public String getQuestionText() { return questionText; }
        public void setQuestionText(String questionText) { this.questionText = questionText; }
        public String getExplanation() { return explanation; }
        public void setExplanation(String explanation) { this.explanation = explanation; }
        public String getOptions() { return options; }
        public void setOptions(String options) { this.options = options; }
        public String getInstructions() { return instructions; }
        public void setInstructions(String instructions) { this.instructions = instructions; }
        public Integer getPassingScorePercent() { return passingScorePercent; }
        public void setPassingScorePercent(Integer passingScorePercent) { this.passingScorePercent = passingScorePercent; }
        public String getQuestionRevisionIds() { return questionRevisionIds; }
        public void setQuestionRevisionIds(String questionRevisionIds) { this.questionRevisionIds = questionRevisionIds; }
    }
}
