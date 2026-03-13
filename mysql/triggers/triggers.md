a Trigger is a piece of SQL code that automatically executes when a specific event occurs on a table.

Events that can trigger it:

INSERT

UPDATE

DELETE

Triggers help automate actions like logging changes, validating data, or maintaining audit tables.


rigger Timing

Triggers run before or after an event.

Type	Meaning
BEFORE INSERT	runs before new row is inserted
AFTER INSERT	runs after row is inserted
BEFORE UPDATE	runs before update
AFTER UPDATE	runs after update
BEFORE DELETE	runs before delete
AFTER DELETE	runs after delete