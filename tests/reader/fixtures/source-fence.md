<!-- shiplog:
kind: source
summary: User message that itself contains a code fence.
-->

Source: test fixture, messages 1-2.
Recorded by: assistant.
Coverage: complete.

### Message 1
Speaker: user

````text
Here is what I tried:

```sh
echo "- [ ] not a task"
```

<!-- shiplog:
kind: decoy
-->
  - [x] also not a task, and   trailing spaces stay   
````

### Message 2
Speaker: assistant

~~~~text
A tilde fence with ~~~ inside it.
~~~
- [ ] still inside the fence
~~~~
