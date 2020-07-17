const colors = ['red', 'black', 'green', 'orange', 'purple', 'cyan', 'blue', 'gray']

function rnd(array) {
  return array[Math.floor(Math.random() * array.length)]
}

export default function TrendLines({ svg, data, x, candles }) {
  let {
    trend_lines: { top: topLines, bottom: bottomLines, strong_top: strongTop, strong_bottom: strongBottom },
  } = data.frames[data.frames.length - 1]

  const categories = [
    { class: 'top', rawLines: topLines, lines: [] },
    { class: 'bottom', rawLines: bottomLines, lines: [] },
    { class: 'strongTop', rawLines: strongTop, lines: [] },
    { class: 'strongBottom', rawLines: strongBottom, lines: [] },
  ]
  for (const category of categories) {
    for (const trendLine of category.rawLines) {
      const line = trendLine.lines[0] //[trendLine.lines.length - 1]
      if (!line) continue
      addPoints(line)
      category.lines.push(line)
      // for (const line of trendLine.lines) {
      // addPoints(line)
      // category.lines.push(line)
      // }
    }
  }

  let y = candles.getY()

  for (const category of categories) {
    category.svg = svg
      .selectAll(`.${category.class}`)
      .data(category.lines)
      .enter()
      .append('line')
      .attr('class', category.class)
      .attr('x1', (d) => x(d.p1.x))
      .attr('x2', (d) => x(d.p2.x))
      .attr('y1', (d) => y(d.p1.y))
      .attr('y2', (d) => y(d.p2.y))
      .attr('stroke', () => rnd(colors))
      .attr('stroke-width', 1)
  }

  function zoomed({ xz }) {
    for (const category of categories) category.svg.attr('x1', (f) => xz(f.p1.x)).attr('x2', (f) => xz(f.p2.x))
  }

  function zoomend() {
    for (const category of categories) {
      category.svg
        .transition()
        .duration(200)
        .attr('y1', (f) => y(f.p1.y))
        .attr('y2', (f) => y(f.p2.y))
    }
  }

  return { zoomed, zoomend }
}

function addPoints(line) {
  if (!Array.isArray(line.p1)) return
  let [x1, y1] = line.p1
  let [x2, y2] = line.p2
  let p1 = { x: x1, y: y1 }
  let p2 = { x: x2, y: y2 }
  line.p1 = p1
  line.p2 = p2
}
