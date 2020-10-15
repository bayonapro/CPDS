# LAB 2 EXERCISES

## Answers to trainings' questions

### Training 1

No question, only implement the code.

### Training 2

_Question_. __Why this misbehavior occur? Why having a big number of savages help us to
find the misbehavior?__

[//]: # (This misbehavior occurs because exists the possibility that 2 threads consults the servings variable at the same time when servings has value 1. After this, both threads can perform the getserving function. Due to that, the servings variable will have the value -1. Since in the if only checks if the variable is either 0 or not, the value of servings will decrease into minus infinite if the Cook doesn't fill the pot.)

This misbehavior occurs because of the if clause. When threads are woken up from the wait(), they do not consult the value of the servings variable again, so if there are more threads awakened than servings available, the servings var will be negative (incorrect behavior).

[//]: # (And yes, having a big number of savages helps to see this misbehavior because the probability of having two threds consulting the servings variariable at the same time when its value is 1 increases.)

And yes, having a big number of savages helps to see this misbehavior because the probability of having more threads awaken at the same time than servings available will be higher.

### Training 3

_Question_. __Explain the origin of the misbehavior. Why the instruction Thread.sleep(200)
in BadPotTwo potentially helps to find the misbehavior.__

The problem of having negative servings is the same as before.

Also, deleting the waits makes the misbehavior occur more often since the threads don't have to wait anymore until some other thread wakes them up.

### Training 4

NO question, only implement the code.
