export default function StrongPoints({ svg, data, x, candles }) {
  let {
    points: { all: points },
  } = data.frames[data.frames.length - 1]

  let y = candles.getY()

  let svgPoints = svg
    .selectAll('.point')
    .data(points)
    .enter()
    .append('circle')
    .attr('class', 'point')
    .attr('cx', (p) => x(p.x))
    .attr('cy', (p) => y(p.y))
    .attr('r', 2)
    .attr('fill', 'black')

  function zoomed({ xz }) {
    svgPoints.attr('cx', (p) => xz(p.x))
  }
  function zoomend() {
    svgPoints
      .transition()
      .duration(200)
      .attr('cy', (p) => y(p.y))
  }

  return { zoomed, zoomend }
}
