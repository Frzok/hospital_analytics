# Hospital Analytics Dashboard

**Анализ медицинской активности и ресурсов многопрофильной больницы на основе обезличенных данных.**

## 📊 Описание проекта

Цель: оптимизация ресурсов и повышение качества медицинской помощи на основе анализа обращений, лабораторной активности и нагрузки на персонал.

Проект выполнен в Power BI с использованием SQL Server, Firebird и справочников ICD-10.

## 🔧 Технологии

- Power BI
- Microsoft SQL Server
- Firebird v3 (источник данных)
- SQL (DDL + представления)
- Excel / Google Sheets (подготовка)

## 📁 Содержимое

- `docs/` — документация проекта и рекомендации;
- `powerbi/` — финальный .pbix-файл отчёта;
- `sql/` — SQL-скрипты создания представлений и индексов;
- `data/` — примеры обезличенных данных (по запросу);
- `screenshots/` — визуальные фрагменты дашбордов.

## 🏥 Госпитализации (Inpatient)

Показаны динамика по месяцам, длительность пребывания, топ-диагнозы, и способы поступления.

![Стационар](screenshots/Inpatient.png)

## 🧪 Лабораторная активность

Анализ возрастных групп, частоты анализов, ACHI-коды, распределение по полу.

![Лаборатория](screenshots/Laboratory.png)

## 🩺 Амбулаторная помощь

Визиты по неделям и месяцам, популярные диагнозы и загруженность врачей.

![Амбулаторно](screenshots/Outpatient.png)

## 📌 Основные выводы

- Пик госпитализаций — IV квартал 2023 года;
- Высокая лабораторная активность в группе 18–35 лет;
- Основная нагрузка на гинекологов и неврологов;
- Отсутствуют данные по занятости коек — исключено из анализа.

## 👩‍💼 Автор

Людмила Черенкова  
Data Analyst | Power BI | SQL | Healthcare Analytics

## 📅 Дата: 17.05.2025
