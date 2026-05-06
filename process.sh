#!/bin/bash
# Raw 폴더 파일 정리 - Claude Code 사용
# 사용법: ./process.sh

RAW_DIR=${1:-~/Documents/Raw}
WIKI_DIR=${2:-~/Documents/WIKI}

echo 📂 Raw: $RAW_DIR
echo 📚 WIKI: $WIKI_DIR

cd $WIKI_DIR || exit 1

# Raw 폴더에 파일이 있는지 체크
files=$(find $RAW_DIR -maxdepth 1 -type f ! -name '.*' 2>/dev/null)
file_count=$(echo $files | wc -w | tr -d ' ')

if [ $file_count -eq 0 ] || [ -z $files ]; then
    echo ⚠️ Raw 폴더에 파일이 없습니다.
    exit 0
fi

echo 📂 $file_count 개의 파일을 처리합니다...

for file in $files; do
    filename=$(basename $file)
    ext=${filename##*.}
    name=${filename%.*}
    
    echo 📄 $filename
    
    if [ ! -d docs ]; then mkdir docs; fi
    
    # Claude Code로 내용 추출
    case $ext in
        pdf)
            claude --print --dangerously-skip-permissions \"
Extract and summarize the content of this PDF file. Output in Korean. Create a well-structured markdown document with: 1) Document title 2) Key summary 3) Main content sections 4) Important details.

File: $file\" > docs/${name}.md 2>/dev/null || echo \"[PDF 처리 실패]\" > docs/${name}.md
            ;;
        png|jpg|jpeg|gif|webp|bmp)
            claude --print --dangerously-skip-permissions \"
Describe this image in detail. Output in Korean markdown format with: 1) Image title 2) Visual description 3) Any text visible 4) Key information.

File: $file\" > docs/${name}.md 2>/dev/null || echo \"[이미지 분석 실패]\" > docs/${name}.md
            ;;
        md|txt|markdown|mdown)
            {
                echo '---'
                echo title: $name
                echo source: $filename
                echo created: $(date '+%Y-%m-%d %H:%M')
                echo 'tags: []'
                echo '---'
                echo
                echo # $name
                echo
            } > docs/${name}.md
            cat $file >> docs/${name}.md
            ;;
        mp3|wav|ogg|m4a)
            claude --print --dangerously-skip-permissions \"
Analyze this audio file. Describe what you hear (music, speech, sound effects, etc.) and provide a summary in Korean.

File: $file\" > docs/${name}.md 2>/dev/null || echo \"[오디오 분석 실패]\" > docs/${name}.md
            ;;
        mp4|mov|avi|mkv)
            claude --print --dangerously-skip-permissions \"
Analyze this video file. Describe what you see (scene, people, action, text, etc.) and provide a summary in Korean.

File: $file\" > docs/${name}.md 2>/dev/null || echo \"[비디오 분석 실패]\" > docs/${name}.md
            ;;
        *)
            {
                echo '---'
                echo title: $name
                echo source: $filename
                echo created: $(date '+%Y-%m-%d %H:%M')
                echo 'tags: []'
                echo '---'
                echo
                echo # $name
                echo
                echo **파일:** $filename
                echo **크기:** $(wc -c < $file) bytes
                echo **타입:** $ext
            } > docs/${name}.md
            ;;
    esac
    
    echo ✅ → docs/${name}.md
done

# index.md 업데이트
{
    echo '# 📚 지식 베이스'
    echo ''
    echo '> Raw 폴더에 파일을 넣으면 AI가 정리해서 여기에归档합니다.'
    echo ''
    echo '---'
    echo ''
    echo '## 📄 문서 목록'
    echo ''
    for doc in docs/*.md; do
        [ -f $doc ] || continue
        title=$(basename $doc .md)
        echo - [$title](docs/$title)
    done
    echo ''
    echo '---'
    echo ''
    echo _최종 업데이트: $(date '+%Y-%m-%d %H:%M') · Claude Code powered_
} > index.md

echo ''
echo ✨ 완료! $file_count 개 파일 처리됨