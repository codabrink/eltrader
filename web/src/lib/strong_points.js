export default function StrongPoints({ svg, data, x, candles }) {
  let {
    points: {
      exclusive: { all: points },
      strong: { all: strongPoints },
    },
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

  let svgStrongPoints = svg
    .selectAll('.strong-point')
    .data(strongPoints)
    .enter()
    .append('circle')
    .attr('class', 'strong-point')
    .attr('cx', (p) => x(p.x))
    .attr('cy', (p) => y(p.y))
    .attr('r', 2)
    .attr('fill', 'red')
    .attr('stroke', 'black')

  function zoomed({ xz }) {
    svgPoints.attr('cx', (p) => xz(p.x))
    svgStrongPoints.attr('cx', (p) => xz(p.x))
  }
  function zoomend() {
    svgPoints
      .transition()
      .duration(200)
      .attr('cy', (p) => y(p.y))
    svgStrongPoints
      .transition()
      .duration(200)
      .attr('cy', (p) => y(p.y))
  }

  return { zoomed, zoomend }
}
