const colors = ['red', 'black', 'green', 'orange', 'purple', 'cyan', 'blue', 'gray']

function rnd(array) {
  return array[Math.floor(Math.random() * array.length)]
}

export default function TrendLines({ svg, data, x, candles }) {
  let {
    trend_lines: { top: topLines, bottom: bottomLines },
  } = data.frames[data.frames.length - 1]

  let _topLines = []
  let _bottomLines = []

  for (const trendLine of topLines) {
    for (const line of trendLine.lines) {
      addPoints(line)
      _topLines.push(line)
    }
  }
  for (const trendLine of bottomLines) {
    for (const line of trendLine.lines) {
      addPoints(line)
      _bottomLines.push(line)
    }
  }

  // for (const line of bottomLines) addPoints(line)

  let y = candles.getY()

  let svgTopLines = svg
    .selectAll('.topline')
    .data(_topLines)
    .enter()
    .append('line')
    .attr('class', 'topline')
    .attr('x1', (d) => x(d.p1.x))
    .attr('x2', (d) => x(d.p2.x))
    .attr('y1', (d) => y(d.p1.y))
    .attr('y2', (d) => y(d.p2.y))
    .attr('stroke', () => rnd(colors))
    .attr('stroke-width', 1)
    .on('click', (d) => console.log(d))

  let svgBottomLines = svg
    .selectAll('.bottomline')
    .data(_bottomLines)
    .enter()
    .append('line')
    .attr('class', 'bottomline')
    .attr('x1', (d) => x(d.p1.x))
    .attr('x2', (d) => x(d.p2.x))
    .attr('y1', (d) => y(d.p1.y))
    .attr('y2', (d) => y(d.p2.y))
    .attr('stroke', (d) => rnd(colors))
    .attr('stroke-width', 1)
    .on('click', (d) => console.log(d))

  function zoomed({ xz }) {
    svgTopLines.attr('x1', (f) => xz(f.p1.x)).attr('x2', (f) => xz(f.p2.x))
    svgBottomLines.attr('x1', (f) => xz(f.p1.x)).attr('x2', (f) => xz(f.p2.x))
  }

  function zoomend() {
    svgTopLines
      .transition()
      .duration(200)
      .attr('y1', (f) => y(f.p1.y))
      .attr('y2', (f) => y(f.p2.y))
    svgBottomLines
      .transition()
      .duration(200)
      .attr('y1', (f) => y(f.p1.y))
      .attr('y2', (f) => y(f.p2.y))
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
