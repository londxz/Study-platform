-- +goose Up
WITH target AS (
    SELECT tp.id
    FROM topics tp
    JOIN sections s ON s.id=tp.section_id
    JOIN tracks tr ON tr.id=s.track_id
    JOIN directions d ON d.id=tr.direction_id
    WHERE d.slug='ios' AND tr.slug='learning' AND s.slug='swift-basics' AND tp.slug='main'
)
INSERT INTO coding_tasks (topic_id,slug,title,statement_markdown,hint,language,starter_code,difficulty,position,status)
SELECT id,'collections-transform','Коллекции и преобразование данных',
       'Получите названия всех непрочитанных статей через filter и map, затем выведите их по одной строке.',
       'Сначала отфильтруйте элементы по isRead, затем преобразуйте результат в массив строк.',
       'swift', $swift$struct Article {
    let title: String
    let isRead: Bool
}

let articles = [
    Article(title: "Value types", isRead: true),
    Article(title: "Protocols", isRead: false),
    Article(title: "Concurrency", isRead: false)
]

// Напишите решение здесь
$swift$,1,1,'published'
FROM target
ON CONFLICT (topic_id,slug) DO NOTHING;

WITH target AS (
    SELECT tp.id
    FROM topics tp
    JOIN sections s ON s.id=tp.section_id
    JOIN tracks tr ON tr.id=s.track_id
    JOIN directions d ON d.id=tr.direction_id
    WHERE d.slug='go' AND tr.slug='learning' AND s.slug='goroutines' AND tp.slug='main'
)
INSERT INTO coding_tasks (topic_id,slug,title,statement_markdown,hint,language,starter_code,difficulty,position,status)
SELECT id,'channel-result','Передача результата через channel',
       'Запустите worker в отдельной горутине, безопасно получите число из канала и выведите result: 42 без sleep и глобальных переменных.',
       'Небуферизованный канал синхронизирует отправителя и получателя.',
       'go', $go$package main

import "fmt"

func worker(result chan<- int) {
	// Отправьте результат
}

func main() {
	result := make(chan int)
	go worker(result)
	fmt.Printf("result: %d\n", <-result)
}
$go$,1,1,'published'
FROM target
ON CONFLICT (topic_id,slug) DO NOTHING;

UPDATE coding_tasks SET starter_code=$swift$final class DownloadService {
    var onComplete: (() -> Void)?

    deinit {
        print("service released")
    }

    func start() {
        onComplete = {
            print("download complete")
        }
    }
}

var service: DownloadService? = DownloadService()
service?.start()
service?.onComplete?()
service = nil
$swift$
WHERE slug='memory-management' AND language='swift';

UPDATE coding_tasks SET starter_code=$go$package main

import (
	"fmt"
	"sync"
)

func main() {
	var wg sync.WaitGroup
	counter := 0
	for i := 0; i < 1000; i++ {
		wg.Add(1)
		go func() {
			defer wg.Done()
			counter++
		}()
	}
	wg.Wait()
	fmt.Println(counter)
}
$go$
WHERE slug='data-race' AND language='go';

-- +goose Down
DELETE FROM coding_tasks WHERE slug IN ('collections-transform','channel-result');
