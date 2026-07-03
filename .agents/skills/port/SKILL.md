---
name: port
description: Porting code and concepts from JavaScript to Dart
version: 0.1.0
tags: [port, javascript, dart]
---

# Porting JavaScript to Dart
This skill focuses on porting code and concepts from JavaScript to Dart, particularly in the context of SVG rendering. It covers best practices for translating JavaScript patterns into Dart idioms, handling type differences, and leveraging Dart's features for clean and efficient code.

## When to Use This Skill
- When you have existing JavaScript code that you want to port to Dart for use in Flutter or server-side applications.

## Planning Phase

1. **Identify the Code to Port**: Determine which JavaScript files or modules and tests you need to port to Dart.
2. **Understand the Code**: Read through the JavaScript code to understand its functionality, dependency graph, and any external libraries it uses.
3. **Map JavaScript Concepts to Dart**: Create a mapping of JavaScript concepts (like classes, functions) to their Dart equivalents.

## Porting Process

Execute for every file identified in planning phase:
1. Create every code unit including private, unused and deprecated ones like interface, type, class, function, argument, variable etc. in Dart with the same name as in JavaScript. Maintain the same order of code units and arguments as in the original JavaScript code.
2. For each code unit, translate the JavaScript syntax and semantics into Dart, ensuring that the functionality remains intact.
3. For functions with multiple args, use named parameters in Dart for better readability.
4. Review names of elements and rename them only if the original name does not follow Dart naming conventions.
5. Use Dart's `late` keyword for variables that are initialized after declaration, and `final` for variables that are assigned once.
6. Use Dart enums to represent simple union types and enums or sealed classes for more complex union types.
7. Use Dart generics for generic programming. 
8. Use Dart's `async` and `await` for asynchronous operations, replacing JavaScript's callback passing style.
9. Use Dart annotations for JS decorators or find an alternative approach if decorator's behavior cannot be fully replicated.
10. If the JavaScript code uses external libraries, find equivalent Dart packages or implement a placeholder implementation with TODO comments if no direct equivalent exists.
11. Use `group` and `test` functions from the `test` package for porting `describe` and `it` blocks, ensuring that description strings are preserved.
