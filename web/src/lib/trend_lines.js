import * as d3 from 'd3'
import { project } from './util'

export default function TrendLines({ svg, data, x, candles }) {
  let {
    frames,
    trend_lines: { top_lines: topLines, bottom_lines: bottomLines },
  } = data

  for (const line of topLines) addPoints(line)
  for (const line of bottomLines) addPoints(line)

  let y = candles.getY()

  console.log(topLines)
  let svgTopLines = svg
    .selectAll('.topline')
    .data(topLines)
    .enter()
    .append('line')
    .attr('class', 'topline')
    .attr('x1', (d) => x(d.p1.x))
    .attr('x2', (d) => x(d.p2.x))
    .attr('y1', (d) => y(d.p1.y))
    .attr('y2', (d) => y(d.p2.y))
    .attr('stroke', (d) => 'black')
}

function addPoints(line) {
  let p1 = { x: line.frame_index, y: line.point.coordinates[1] }
  let p2 = project(p1, line.angle, 500)
  line.p1 = p1
  line.p2 = p2
}
