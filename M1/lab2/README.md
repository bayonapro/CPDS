# LAB 2 EXERCISES

## Answers to trainings' questions

### Training 1

No question, only implement the code.

### Training 2

_Question_. __Why this misbehavior occur? Why having a big number of savages help us to
find the misbehavior?__

This misbehavior occurs because exists the possibility that 2 threads consults the servings variable at the same time when servings has value 1. After this, both threads can perform the getserving function. Due to that, the servings variable will have the value -1. Since in the if only checks if the variable is either 0 or not, the value of servings will decrease into minus infinite if the Cook doesn't fill the pot.

And yes, having a big number of savages helps to see this misbehavior because the probability of having two threds consulting the servings variariable at the same time when its value is 1 increases.

### Training 3

_Question_. __Explain the origin of the misbehavior. Why the instruction Thread.sleep(200)
in BadPotTwo potentially helps to find the misbehavior.__

The problem of having negative servings is the same as before.

Also, deleting the waits makes the misbehavior occur more often since the threads don't have to wait anymore.

### Training 4

NO question, only implement the code.
