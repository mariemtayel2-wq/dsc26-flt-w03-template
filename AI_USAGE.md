# AI usage: dsc26-flt-w03

AI tools are allowed in this task. Fill in every section in your own words. This file is read by your Track Mentor, not by the grader.

## 1. Tools I used

<!-- Write "none" if you used none. -->
Gemini and GitHub Copilot

## 2. The prompts that helped most

<!-- Paraphrasing is fine. -->

1. Review my Flutter code against the task requirements and explain what needs repair and why.
2. Check the API URL building, response validation, retry policy, and screen lifecycle behavior against hidden-test scenarios.

## 3. Where the assistant's code would have failed a hidden-test area, and how I noticed

<!-- For example: it used response.body, retried a 401, forgot the disposed check, ignored Retry-After. Say which row (H01-H13) it would have failed and what made you notice. -->

The initial implementation could have failed H06 because it used `int.tryParse` for
`Retry-After` without explicitly rejecting negative or otherwise invalid values. I
noticed this by comparing the implementation with the requirement that invalid
values, decimal values, and HTTP dates must fall back to 5 seconds.

## 4. My state-management choice

<!-- ChangeNotifier, Riverpod 3 or Bloc/Cubit, and one sentence on why. -->

I chose ChangeNotifier because it is simple for this small screen and keeps loading,
success, and failure state separate from the widget UI.
