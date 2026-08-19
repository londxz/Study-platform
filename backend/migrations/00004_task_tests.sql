-- +goose Up
UPDATE coding_tasks
SET starter_code = replace(starter_code, E'\\n', E'\n')
WHERE starter_code LIKE E'%\\n%';

INSERT INTO coding_task_tests (coding_task_id,stdin,expected_stdout,hidden,position)
SELECT id,'',E'Protocols\nConcurrency\n',true,1
FROM coding_tasks
WHERE slug='collections-transform' AND language='swift'
  AND NOT EXISTS (SELECT 1 FROM coding_task_tests WHERE coding_task_id=coding_tasks.id);

INSERT INTO coding_task_tests (coding_task_id,stdin,expected_stdout,hidden,position)
SELECT id,'',E'result: 42\n',true,1
FROM coding_tasks
WHERE slug='channel-result' AND language='go'
  AND NOT EXISTS (SELECT 1 FROM coding_task_tests WHERE coding_task_id=coding_tasks.id);

-- +goose Down
DELETE FROM coding_task_tests
WHERE coding_task_id IN (
    SELECT id FROM coding_tasks
    WHERE (slug='collections-transform' AND language='swift')
       OR (slug='channel-result' AND language='go')
);
